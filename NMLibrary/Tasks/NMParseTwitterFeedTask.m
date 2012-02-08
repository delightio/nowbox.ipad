//
//  NMParseTwitterFeedTask.m
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseTwitterFeedTask.h"
#import "NMParseFacebookFeedTask.h"
#import "NMDataController.h"
#import "NMObjectCache.h"

#import "NMChannel.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMPersonProfile.h"
#import "NMSubscription.h"

NSString * const NMWillParseTwitterFeedNotification = @"NMWillParseTwitterFeedNotification";
NSString * const NMDidParseTwitterFeedNotification = @"NMDidParseTwitterFeedNotification";
NSString * const NMDidFailParseTwitterFeedNotification = @"NMDidFailParseTwitterFeedNotification";

@implementation NMParseTwitterFeedTask
@synthesize channel = _channel;
@synthesize account = _account;
@synthesize page = _page;
@synthesize sinceID = _sinceID;
@synthesize profileArray = _profileArray;
@synthesize newestTwitIDString = _newestTwitIDString;


- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)acObj {
	self = [super init];
	command = NMCommandParseTwitterFeed;
	self.channel = chnObj;
	self.account = acObj;
	self.sinceID = chnObj.subscription.nm_since_id;
	return self;
}

- (id)initWithInfo:(NSDictionary *)aDict {
	self = [super init];
	command = NMCommandGetTwitterProfile;
	self.channel = [aDict objectForKey:@"channel"];
	self.account = [aDict objectForKey:@"account"];
	self.sinceID = [aDict objectForKey:@"since_id"];
	self.page = [[aDict objectForKey:@"next_page"] integerValue];
	return self;
}

- (void)dealloc {
	[_channel release];
	[_account release];
	[_sinceID release];
	[_profileArray release];
	[_newestTwitIDString release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSDictionary * params = nil;
	if ( _sinceID ) {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSString stringWithFormat:@"%d", _page], @"page", _sinceID, @"since_id", @"1", @"include_entities", nil];
	} else {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSString stringWithFormat:@"%d", _page], @"page", @"1", @"include_entities", nil];
	}
	TWRequest * twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/friends_timeline.json"] parameters:params requestMethod:TWRequestMethodGET];
	twitRequest.account = _account;
	NSURLRequest * req = [twitRequest signedURLRequest];
	[twitRequest release];
	return req;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	NSArray * objAy = [buffer objectFromJSONData];
	
	NSUInteger feedCount = [objAy count];
	if ( feedCount == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:feedCount];
	self.profileArray = [NSMutableArray arrayWithCapacity:feedCount];
	NSDictionary * entityDict;
	NSArray * urls;
	NSDictionary * urlDict;
	NSString * extID;
	for (NSDictionary * twDict in objAy) {
		if ( _page == 0 && _newestTwitIDString == nil ) {
			self.newestTwitIDString = [twDict objectForKey:@"id_str"];
		}
		// grab the "entities" attribute
		entityDict = [twDict objectForKey:@"entities"];
		urls = [entityDict objectForKey:@"urls"];
		if ( urls ) {
			// check if the entity contains any URL link
			for (urlDict in urls) {
				extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[urlDict	objectForKey:@"expanded_url"]];
				if ( extID ) {
					// the url contains a Youtube external ID
					[parsedObjects addObject:extID];
					// save the person who submit this tweet
					[_profileArray addObject:[twDict objectForKey:@"user"]];
				}
			}
		}
	}
	if ( [parsedObjects count] == 0 ) {
		[parsedObjects release], parsedObjects = nil;
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( parsedObjects == nil ) return NO;
	
	// iterate through all external ID. check if we need to create NMVideo and related mananged object structure
	NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:_channel sessionOnly:YES] + 1;
	NSInteger theProfileOrder = [ctrl maxPersonProfileID] + 1;
	NMObjectCache * objectCache = [[NMObjectCache alloc] init];
	NSNumber * errNum = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
	NSNumber * bigSessionNum = [NSNumber numberWithInteger:NSIntegerMax];
	// enumerate the feed
	[parsedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString * extID = obj;
		NMConcreteVideo * conVdo = nil;
		NMVideo * vdo = nil;
		NMVideoExistenceCheckResult chkResult = [ctrl videoExistsWithExternalID:extID channel:_channel targetVideo:&conVdo];
		switch (chkResult) {
			case NMVideoExistsButNotInChannel:
				// create only the NMVideo object
				vdo = [ctrl insertNewVideo];
				vdo.channel = _channel;
				vdo.nm_session_id = bigSessionNum;
				vdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
				break;
				
			case NMVideoDoesNotExist:
				// create the NMVideo and NMConcreteVideo objects
				conVdo = [ctrl insertNewConcreteVideo];
				conVdo.external_id = extID;
				conVdo.nm_error = errNum;
				conVdo.source = [NSNumber numberWithInteger:NMVideoSourceYouTube];
				// create video
				vdo = [ctrl insertNewVideo];
				vdo.video = conVdo;
				vdo.channel = _channel;
				vdo.nm_session_id = bigSessionNum;
				vdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
				break;
				
			default:
				break;
		}
		// check person profile
		if ( vdo ) {
			BOOL isNew = NO;
			id fromDict = [_profileArray objectAtIndex:idx];
			if ( fromDict != [NSNull null] ) {
				NSString * manID = [fromDict objectForKey:@"id_str"];
				NMPersonProfile * theProfile = [objectCache objectForKey:manID];
				if ( theProfile == nil ) {
					theProfile = [ctrl insertNewPersonProfileWithID:manID isNew:&isNew];
					[objectCache setObject:theProfile forKey:manID];
				}
				if ( isNew ) {
					// Twitter feed JSON provides enough user info to generate a full detail NMPersonProfile object. Therefore, no need to generate any "person profile task".
					theProfile.nm_id = [NSNumber numberWithInteger:theProfileOrder + idx];
					theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
					theProfile.first_name = [fromDict objectForKey:@"name"];
					theProfile.nm_error = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
					NSString * scName = [fromDict objectForKey:@"screen_name"];
					if ( scName ) theProfile.username = scName;
				}
				vdo.personProfile = theProfile;
			}
		}
	}];
	// update the last checked time
	_channel.subscription.nm_last_crawled = [NSDate date];
	// only update the since ID if we are parsing the first page. The rest of the tweets in other pages will have ID smaller than this one
	if ( _page == 0 ) _channel.subscription.nm_since_id = _newestTwitIDString;
	[objectCache release];
	return YES;
}

- (NSString *)willLoadNotificationName {
	return NMWillParseTwitterFeedNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidParseTwitterFeedNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailParseTwitterFeedNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_received", [NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_added", _channel, @"channel", _account, @"account", [NSNumber numberWithInteger:_page + 1], @"next_page", _sinceID, @"since_id", nil];
}

@end
