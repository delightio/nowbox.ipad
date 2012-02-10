//
//  NMParseFacebookFeedTask.m
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseFacebookFeedTask.h"
#import "NMDataController.h"
#import "NMNetworkController.h"
#import "NMAccountManager.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMPersonProfile.h"
#import "NMSubscription.h"
#import "NMFacebookInfo.h"
#import "NMFacebookComment.h"
#import "FBConnect.h"
#import "NMObjectCache.h"

NSString * const NMWillParseFacebookFeedNotification = @"NMWillParseFacebookFeedNotification";
NSString * const NMDidParseFacebookFeedNotification = @"NMDidParseFacebookFeedNotification";
NSString * const NMDidFailParseFacebookFeedNotification = @"NMDidFailParseFacebookFeedNotification";

static NSArray * youTubeRegexArray = nil;

@implementation NMParseFacebookFeedTask

@synthesize channel = _channel;
@synthesize nextPageURLString = _nextPageURLString;
@synthesize user_id = _user_id;
@synthesize since_id = _since_id;
@synthesize profileArray = _profileArray;
@synthesize feedDirectURLString = _feedDirectURLString;
@synthesize videoLikeDict = _videoLikeDict;
@synthesize videoCommentDict = _videoCommentDict;

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	command = NMCommandParseFacebookFeed;
	self.channel = chn;
	self.since_id = chn.subscription.nm_since_id;
	if ( _since_id == nil || [_since_id isEqualToString:@""]) self.since_id = @"0";
	NMPersonProfile * theProfile =  chn.subscription.personProfile;
	self.user_id = theProfile.nm_user_id;
	isAccountOwner = [theProfile.nm_me boolValue];
	self.targetID = chn.nm_id;
	return self;
}

- (id)initWithChannel:(NMChannel *)chn directURLString:(NSString *)urlStr {
	self = [super init];
	
	command = NMCommandParseFacebookFeed;
	self.feedDirectURLString = urlStr;
	self.channel = chn;
	NMPersonProfile * theProfile =  chn.subscription.personProfile;
	self.user_id = theProfile.nm_user_id;
	isAccountOwner = [theProfile.nm_me boolValue];
	self.targetID = chn.nm_id;
	
	return self;
}

- (void)dealloc {
	[_user_id release];
	[_since_id release];
	[_channel release];
	[_nextPageURLString release];
	[_profileArray release];
	[_feedDirectURLString release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	// home - user's news feed
	// feed - user's own wall
	NSString * thePath;
	if ( isAccountOwner ) {
		thePath = @"me/home";
	} else {
		thePath = [NSString stringWithFormat:@"%@/feed", _user_id];
	}
	NSMutableDictionary * theDict = nil;
	if ( _feedDirectURLString ) {
		NSURL * theURL = [NSURL URLWithString:_feedDirectURLString];
		theDict = [NSMutableDictionary dictionaryWithDictionary:[self.facebook parseURLParams:[theURL query]]];
	} else {
		theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"50", @"limit", @"U", @"date_format", _since_id, @"since", nil];
	}
	return [self.facebook requestWithGraphPath:thePath andParams:theDict andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	// home - user's news feed
	// feed - user's own wall
	NSArray * feedAy = [result valueForKeyPath:@"data"];
	
	NSUInteger feedCount = [feedAy count];
	if ( feedCount == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:feedCount];
	self.profileArray = [NSMutableArray arrayWithCapacity:feedCount];
	NSString * extID = nil;
	NSString * dataType = nil;
	NSDictionary * fromDict = nil;
	NSInteger theTime;
	NSDictionary * otherDict;
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		dataType = [theDict objectForKey:@"type"];
		if ( [dataType isEqualToString:@"video"] || [dataType isEqualToString:@"link"] ) {
			extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[theDict objectForKey:@"link"]];
			if ( extID ) {
				// we just need the external ID
				[parsedObjects addObject:extID];
				theTime = [[theDict objectForKey:@"updated_time"] integerValue];
				otherDict = [theDict objectForKey:@"likes"];
				if ( otherDict ) [_videoLikeDict setObject:otherDict forKey:extID];
				otherDict = [theDict objectForKey:@"comments"];
				if ( otherDict ) [_videoCommentDict setObject:otherDict forKey:extID];
				if ( theTime > maxUnixTime ) maxUnixTime = theTime;
			} /*else {
				NSLog(@"not added: %@ %@", [theDict objectForKey:@"name"], [theDict objectForKey:@"link"]);
			}*/
		}
		fromDict = [theDict objectForKey:@"from"];
		if ( fromDict ) [_profileArray addObject:fromDict];
		else [_profileArray addObject:[NSNull null]];
	}
	if ( [parsedObjects count] == 0 ) {
		[parsedObjects release];
		parsedObjects = nil;
	}
	self.nextPageURLString = [result valueForKeyPath:@"paging.next"];
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( parsedObjects == nil ) return NO;
	
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
		if ( vdo ) {
			// check person profile
			BOOL isNew = NO;
			id fromDict = [_profileArray objectAtIndex:idx];
			if ( fromDict != [NSNull null] ) {
				NSString * manID = [fromDict objectForKey:@"id"];
				NMPersonProfile * theProfile = [objectCache objectForKey:manID];
				if ( theProfile == nil ) {
					theProfile = [ctrl insertNewPersonProfileWithID:manID isNew:&isNew];
					[objectCache setObject:theProfile forKey:manID];
				}
				if ( isNew ) {
					theProfile.nm_id = [NSNumber numberWithInteger:theProfileOrder + idx];
					theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
					theProfile.first_name = [fromDict objectForKey:@"name"];
					theProfile.nm_error = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
				}
				vdo.personProfile = theProfile;
			}
			// check likes
			NSDictionary * otherDict = [_videoCommentDict objectForKey:extID];
			NMFacebookInfo * fbInfo;
			if ( otherDict ) {
				fbInfo = vdo.video.facebook_info;
				if ( fbInfo == nil ) {
					fbInfo = [ctrl insertNewFacebookInfo];
					vdo.video.facebook_info = fbInfo;
				}
				// there are some comments in this video. add the comment
				fbInfo.likes_count = [otherDict objectForKey:@"count"];
			}
			// check comments
			otherDict = [_videoLikeDict objectForKey:extID];
			if ( otherDict ) {
				fbInfo = vdo.video.facebook_info;
				if ( fbInfo == nil ) {
					fbInfo = [ctrl insertNewFacebookInfo];
					vdo.video.facebook_info = fbInfo;
				}
				// someone has liked this video
				fbInfo.comments_count = [otherDict objectForKey:@"count"];
				// remove all comments and reinsert everything
				NSArray * cmtAy = [otherDict objectForKey:@"data"];
				NSMutableSet * cmtSet = [NSMutableSet setWithCapacity:[cmtAy count]];
				NMFacebookComment * cmtObj;
				for (NSDictionary * cmtDict in cmtAy) {
					cmtObj = [ctrl insertNewFacebookComment];
					cmtObj.message = [cmtDict objectForKey:@"message"];
					cmtObj.created_time = [cmtDict objectForKey:@"created_time"];
					// look up the person
					
					[cmtSet addObject:cmtObj];
				}
			}
		}
	}];
	// when first fire Facebook feed parsing task, feedDirectURLString is nil. This means we are getting the first page of a person's news feed. The newest item should always appear in the first page. Therefore, we only need to save the parsing time data under this condition.
	if ( _feedDirectURLString && maxUnixTime > [_channel.subscription.nm_since_id integerValue] ) {
		// update the last checked time
		_channel.subscription.nm_since_id = [NSString stringWithFormat:@"%d", maxUnixTime];
		_channel.subscription.nm_last_crawled = [NSDate date];
	}
	[objectCache release];
	return YES;
}

+ (NSString *)youTubeExternalIDFromLink:(NSString *)urlStr {
	if ( urlStr == nil ) return NO;
	if ( youTubeRegexArray == nil ) {
		youTubeRegexArray = [[NSArray alloc] initWithObjects:
							 [NSRegularExpression regularExpressionWithPattern:@"youtube\\.com/watch\\?v=([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 [NSRegularExpression regularExpressionWithPattern:@"youtu\\.be/([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 [NSRegularExpression regularExpressionWithPattern:@"y2u\\.be/([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 nil];
	}
	NSString * extID = nil;
	NSTextCheckingResult * result = nil;
	for (NSRegularExpression * regex in youTubeRegexArray) {
		result = [regex firstMatchInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])];
		if ( result && [result numberOfRanges] > 1) {
			extID = [urlStr substringWithRange:[result rangeAtIndex:1]];
			break;
		}
	}
	return extID;
}

- (NSString *)willLoadNotificationName {
	return NMWillParseFacebookFeedNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidParseFacebookFeedNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailParseFacebookFeedNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_received", [NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_added", _channel, @"channel", _nextPageURLString, @"next_url", nil];
}

@end
