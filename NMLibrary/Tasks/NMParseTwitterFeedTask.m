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
#import "NMAccountManager.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMPersonProfile.h"
#import "NMSubscription.h"
#import "NMSocialInfo.h"
#import "NMSocialComment.h"
#import "NMObjectCache.h"

NSString * const NMWillParseTwitterFeedNotification = @"NMWillParseTwitterFeedNotification";
NSString * const NMDidParseTwitterFeedNotification = @"NMDidParseTwitterFeedNotification";
NSString * const NMDidFailParseTwitterFeedNotification = @"NMDidFailParseTwitterFeedNotification";

@implementation NMParseTwitterFeedTask
@synthesize channel = _channel;
@synthesize account = _account;
@synthesize page = _page;
@synthesize since_id = _since_id;
@synthesize user_id = _user_id;
@synthesize newestTwitIDString = _newestTwitIDString;
@synthesize feedDateFormatter = _feedDateFormatter;
@synthesize twitterTypeNumber = _twitterTypeNumber;

- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)acObj {
	self = [super init];
	command = NMCommandParseTwitterFeed;
	self.channel = chnObj;
	self.account = acObj;
	self.since_id = chnObj.subscription.nm_since_id;
	NMPersonProfile * thePerson = chnObj.subscription.personProfile;
	isAccountOwner = [thePerson.nm_me boolValue];
	self.user_id = thePerson.nm_user_id;
	return self;
}

- (id)initWithInfo:(NSDictionary *)aDict {
	self = [super init];
	command = NMCommandGetTwitterProfile;
	self.channel = [aDict objectForKey:@"channel"];
	self.account = [aDict objectForKey:@"account"];
	self.since_id = [aDict objectForKey:@"since_id"];
	self.page = [[aDict objectForKey:@"next_page"] integerValue];
	NMPersonProfile * thePerson = _channel.subscription.personProfile;
	isAccountOwner = [thePerson.nm_me boolValue];
	self.user_id = thePerson.nm_user_id;
	return self;
}

- (void)dealloc {
	[_channel release];
	[_account release];
	[_since_id release];
	[_user_id release];
	[_newestTwitIDString release];
	[_feedDateFormatter release];
	[_twitterTypeNumber release];
	[super dealloc];
}

- (NSDateFormatter *)feedDateFormatter {
	if ( _feedDateFormatter == nil ) {
		_feedDateFormatter = [[NSDateFormatter alloc] init];
		[_feedDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZ yyyy"];
	}
	return _feedDateFormatter;
}

- (NSNumber *)twitterTypeNumber {
	if ( _twitterTypeNumber == nil ) {
		_twitterTypeNumber = [[NSNumber numberWithInteger:NMChannelUserTwitterType] retain];
	}
	return _twitterTypeNumber;
}

- (NSURLRequest *)URLRequest {
	NSMutableDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:@"100", @"count", [NSString stringWithFormat:@"%d", _page], @"page", @"1", @"include_entities", @"0", @"include_rts", nil];
	
	if ( _since_id ) {
		[params setObject:_since_id forKey:@"since_id"];
	}
	if ( !isAccountOwner ) {
		// specify the user ID
		[params setObject:_user_id forKey:@"user_id"];
	}
	
	NSString * urlStr = nil;
	if ( isAccountOwner ) {
		urlStr = @"http://api.twitter.com/1/statuses/home_timeline.json";
	} else {
		// read the user's own post
		urlStr = @"http://api.twitter.com/1/statuses/user_timeline.json";
	}
	TWRequest * twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:urlStr] parameters:params requestMethod:TWRequestMethodGET];
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
	NSDictionary * entityDict;
	NSArray * urls;
	NSDictionary * urlDict;
	NSString * extID;
	NSMutableDictionary * vdoDict = nil;
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
					vdoDict = [NSMutableDictionary dictionaryWithCapacity:4];
					// the url contains a Youtube external ID
					[vdoDict setObject:extID forKey:@"external_id"];
					[vdoDict setObject:[twDict objectForKey:@"id_str"] forKey:@"object_id"];
					[vdoDict setObject:[twDict objectForKey:@"text"] forKey:@"message"];
					[vdoDict setObject:[NSNumber numberWithDouble:[[self.feedDateFormatter dateFromString:[twDict objectForKey:@"created_at"]] timeIntervalSince1970]] forKey:@"created_time"];
					// save the person who submit this tweet
					[vdoDict setObject:[twDict objectForKey:@"user"] forKey:@"from"];
					[parsedObjects addObject:vdoDict];
				}
			}
		}
	}
	if ( [parsedObjects count] == 0 ) {
		[parsedObjects release], parsedObjects = nil;
	}
}

- (void)setupPersonProfile:(NMPersonProfile *)theProfile withID:(NSInteger)theID {
	theProfile.nm_id = [NSNumber numberWithInteger:theID];
	theProfile.nm_type = self.twitterTypeNumber;
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( parsedObjects == nil ) return NO;
	
	// iterate through all external ID. check if we need to create NMVideo and related mananged object structure
	NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:_channel sessionOnly:YES] + 1;
	NSInteger personIDBase = [ctrl maxPersonProfileID];
	NMObjectCache * objectCache = [[NMObjectCache alloc] init];
	NSNumber * errNum = [NSNumber numberWithInteger:NMErrorPendingImport];
	NSNumber * bigSessionNum = [NSNumber numberWithInteger:NSIntegerMax];
	// enumerate the feed
	NSInteger idx = -1;
	NSInteger personIDOffset = 0;
	NMSocialInfo * fbInfo;
	NMConcreteVideo * conVdo = nil;
	NMVideo * vdo = nil;
	NSString * extID;
	for (NSDictionary * vdoFeedDict in parsedObjects) {
		extID = [vdoFeedDict objectForKey:@"external_id"];
		idx++;
		fbInfo = nil;
		NMVideoExistenceCheckResult chkResult = [ctrl videoExistsWithExternalID:extID channel:_channel targetVideo:&conVdo];
		switch (chkResult) {
			case NMVideoExistsButNotInChannel:
			{
				// create only the NMVideo object
				vdo = [ctrl insertNewVideo];
				vdo.channel = _channel;
				vdo.nm_session_id = bigSessionNum;
				vdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
				vdo.video = conVdo;
				// check if the set contains the info from this person already
				NSSet * fbMtnSet = conVdo.socialMentions;
				BOOL postFound = NO;
				for (fbInfo in fbMtnSet) {
					if ( [fbInfo.nm_type integerValue] == NMChannelUserTwitterType && [fbInfo.object_id isEqualToString:[vdoFeedDict objectForKey:@"object_id"]] ) {
						postFound = YES;
						break;
					}
				}
				if ( !postFound ) {
					// create facebook info
					fbInfo = [ctrl insertNewSocialInfo];
					fbInfo.video = vdo.video;
					fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
					// set the link
					fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
				} // else - object clean up will be done later below.
				break;
			}
			case NMVideoDoesNotExist:
				numberOfVideoAdded++;
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
				// create twitter info
				fbInfo = [ctrl insertNewSocialInfo];
				fbInfo.video = conVdo;
				fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
				// set the link
				fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
				break;
				
			case NMVideoExistsAndInChannel:
			{
				conVdo = vdo.video;
				NSSet * fbMtnSet = conVdo.socialMentions;
				BOOL postFound = NO;
				for (fbInfo in fbMtnSet) {
					if ( [fbInfo.object_id isEqualToString:[vdoFeedDict objectForKey:@"object_id"]] ) {
						postFound = YES;
						break;
					}
				}
				if ( !postFound ) {
					// create facebook info
					fbInfo = [ctrl insertNewSocialInfo];
					fbInfo.video = vdo.video;
					fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
					// set the link
					fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
				} // else - object clean up will be done later below.
				break;
			}
			default:
				break;
		}
		if ( vdo ) {
			NSLog(@"working on video: %@, post: %@", conVdo.title, fbInfo.object_id);
			// check person profile
			BOOL isNew = NO;
			NSDictionary * fromDict = [vdoFeedDict objectForKey:@"from"];
			NSString * manID;
			NMPersonProfile * theProfile;
			if ( fromDict ) {
				manID = [fromDict objectForKey:@"id_str"];
				theProfile = [objectCache objectForKey:manID];
				if ( theProfile == nil ) {
					// search for existing or insert new person
					theProfile = [ctrl insertNewPersonProfileWithID:manID type:self.twitterTypeNumber isNew:&isNew];
					[objectCache setObject:theProfile forKey:manID];
				}
				if ( isNew ) {
					personIDOffset++;
					[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
					theProfile.name = [fromDict objectForKey:@"name"];
					NSString * scName = [fromDict objectForKey:@"screen_name"];
					if ( scName ) theProfile.username = scName;
					scName = [fromDict objectForKey:@"profile_image_url"];
					if ( scName ) theProfile.picture = scName;
					// subscribe to this person as well
					[ctrl subscribeUserChannelWithPersonProfile:theProfile];
				}
				if ( ![_user_id isEqual:manID] ) {
					// the video is from another person. we should add the video to that person's channel as well
					if ( isNew || chkResult == NMVideoDoesNotExist ) {
						// this person profile is now. i.e. just insert the video to thi channel
						// add the video into the channel
						NMVideo * personVdo = [ctrl insertNewVideo];
						personVdo.video = conVdo;
						// add the new video proxy object to the person's channel
						personVdo.channel = theProfile.subscription.channel;
						personVdo.nm_session_id = bigSessionNum;
						personVdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
					} else if ( !isNew && chkResult == NMVideoExistsButNotInChannel ) {
						// check if the vido exists in this person's channel
						NMChannel * personChn = theProfile.subscription.channel;
						chkResult = [ctrl videoExistsWithExternalID:extID channel:personChn targetVideo:&conVdo];
						if ( chkResult == NMVideoExistsButNotInChannel ) {
							// add the video into the channel
							NMVideo * personVdo = [ctrl insertNewVideo];
							personVdo.video = conVdo;
							// add the new video proxy object to the person's channel
							personVdo.channel = personChn;
							personVdo.nm_session_id = bigSessionNum;
							personVdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
						}
					}
				}
				// save the tweet in the Comment object
				BOOL saveTweet = YES;
				if ( [fbInfo.comments count] ) {
					// check if the tweet is already saved
					saveTweet = [[fbInfo.comments filteredSetUsingPredicate:[ctrl.socialObjectIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[vdoFeedDict objectForKey:@"object_id"] forKey:@"OBJECT_ID"]]] count] == 0;
				}
				if ( saveTweet ) {
					NMSocialComment * cmtObj = [ctrl insertNewSocialComment];
					cmtObj.message = [vdoFeedDict objectForKey:@"message"];
					cmtObj.created_time = [vdoFeedDict objectForKey:@"created_time"];
					cmtObj.object_id = [vdoFeedDict objectForKey:@"object_id"];
					cmtObj.socialInfo = fbInfo;
					// look up the person
					fromDict = [vdoFeedDict objectForKey:@"from"];
					cmtObj.fromPerson = theProfile;
#ifdef DEBUG_TWITTER_IMPORT
					NSLog(@"add tweet: %@", cmtObj.message);
#endif
				}
			}
		}
	}
	// update the last checked time
	_channel.subscription.nm_video_last_refresh = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
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
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_received", [NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_added", _channel, @"channel", _account, @"account", [NSNumber numberWithInteger:_page + 1], @"next_page", _since_id, @"since_id", nil];
}

@end
