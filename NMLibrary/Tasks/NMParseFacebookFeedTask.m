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
@synthesize feedDirectURLString = _feedDirectURLString;

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
	[_feedDirectURLString release];
	[super dealloc];
}

- (void)setupPersonProfile:(NMPersonProfile *)theProfile withID:(NSInteger)theID {
	theProfile.nm_id = [NSNumber numberWithInteger:theID];
	theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
	theProfile.nm_error = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
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
	NSString * extID = nil;
	NSString * dataType = nil;
	NSInteger theTime;
	NSDictionary * otherDict;
	NSMutableDictionary * vdoDict = nil;
	NSArray * theActions;
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		dataType = [theDict objectForKey:@"type"];
		if ( [dataType isEqualToString:@"video"] || [dataType isEqualToString:@"link"] ) {
			extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[theDict objectForKey:@"link"]];
			if ( extID && theActions ) {
				vdoDict = [NSMutableDictionary dictionaryWithCapacity:4];
				// we just need the external ID
				[vdoDict setObject:extID forKey:@"external_id"];
				[vdoDict setObject:[theDict objectForKey:@"id"] forKey:@"object_id"];
				theTime = [[theDict objectForKey:@"updated_time"] integerValue];
				
				otherDict = [theDict objectForKey:@"likes"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"likes"];
				
				otherDict = [theDict objectForKey:@"comments"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"comments"];
				
				otherDict = [theDict objectForKey:@"from"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"from"];
				
				// action URLs
				theActions = [theDict objectForKey:@"actions"];
				for (otherDict in theActions) {
					NSString * theActionName = [[otherDict objectForKey:@"name"] lowercaseString];
					if ( [theActionName isEqualToString:@"comment"] ) {
						[vdoDict setObject:[otherDict objectForKey:@"link"] forKey:@"comment_post_url"];
					} else if ( [theActionName isEqualToString:@"like"] ) {
						[vdoDict setObject:[otherDict objectForKey:@"link"] forKey:@"like_post_url"];
					}
				}

				if ( theTime > maxUnixTime ) maxUnixTime = theTime;
				
				[parsedObjects addObject:vdoDict];
			} /*else {
				NSLog(@"not added: %@ %@", [theDict objectForKey:@"name"], [theDict objectForKey:@"link"]);
			}*/
		}
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
	NSInteger personIDBase = [ctrl maxPersonProfileID];
	NMObjectCache * objectCache = [[NMObjectCache alloc] init];
	NSNumber * errNum = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
	NSNumber * bigSessionNum = [NSNumber numberWithInteger:NSIntegerMax];
	// enumerate the feed
	NSInteger idx = -1;
	NSInteger personIDOffset = 0;
	NMFacebookInfo * fbInfo;
	NMConcreteVideo * conVdo = nil;
	NMVideo * vdo = nil;
	NSString * extID;
	for (NSDictionary * vdoFeedDict in parsedObjects) {
		extID = [vdoFeedDict objectForKey:@"external_id"];
		idx++;
		NMVideoExistenceCheckResult chkResult = [ctrl videoExistsWithExternalID:extID channel:_channel targetVideo:&conVdo];
		switch (chkResult) {
			case NMVideoExistsButNotInChannel:
			{
				// create only the NMVideo object
				vdo = [ctrl insertNewVideo];
				vdo.channel = _channel;
				vdo.nm_session_id = bigSessionNum;
				vdo.nm_sort_order = [NSNumber numberWithInteger:theOrder + idx];
				conVdo = vdo.video;
				// check if the set contains the info from this person already
				NSSet * fbMtnSet = conVdo.facebookMentions;
				BOOL postFound = NO;
				for (fbInfo in fbMtnSet) {
					if ( [fbInfo.object_id isEqualToString:[vdoFeedDict objectForKey:@"object_id"]] ) {
						postFound = YES;
						break;
					}
				}
				if ( !postFound ) {
					// create facebook info
					fbInfo = [ctrl insertNewFacebookInfo];
					fbInfo.video = vdo.video;
					// set the link
					fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
					fbInfo.comment_post_url = [vdoFeedDict objectForKey:@"comment_post_url"];
					fbInfo.like_post_url = [vdoFeedDict objectForKey:@"like_post_url"];
				} // else - object clean up will be done later below.
				break;
			}
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
				// create facebook info
				fbInfo = [ctrl insertNewFacebookInfo];
				fbInfo.video = conVdo;
				// set the link
				fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
				fbInfo.comment_post_url = [vdoFeedDict objectForKey:@"comment_post_url"];
				fbInfo.like_post_url = [vdoFeedDict objectForKey:@"like_post_url"];
				break;
				
			default:
				break;
		}
		if ( vdo ) {
			// check person profile
			BOOL isNew = NO;
			NSDictionary * fromDict = [vdoFeedDict objectForKey:@"from"];
			NSString * manID;
			NMPersonProfile * theProfile;
			if ( fromDict ) {
				manID = [fromDict objectForKey:@"id"];
				theProfile = [objectCache objectForKey:manID];
				if ( theProfile == nil ) {
					theProfile = [ctrl insertNewPersonProfileWithID:manID isNew:&isNew];
					[objectCache setObject:theProfile forKey:manID];
				}
				if ( isNew ) {
					personIDOffset++;
					[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
					theProfile.name = [fromDict objectForKey:@"name"];
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
			}
			// check likes
			NSDictionary * otherDict = [vdoFeedDict objectForKey:@"likes"];
			if ( otherDict && [[otherDict objectForKey:@"count"] integerValue] ) {
				// there are some comments in this video. add the comment
				fbInfo.likes_count = [otherDict objectForKey:@"count"];
				// remove all existing relationship and reinsert new ones
				if ( [fbInfo.peopleLike count] ) {
					[fbInfo setPeopleLike:nil];
				}
				NSArray * lkAy = [otherDict objectForKey:@"data"];
				NSMutableSet * lkSet = [NSMutableSet setWithCapacity:[lkAy count]];
				for (fromDict in lkAy) {
					manID = [fromDict objectForKey:@"id"];
					theProfile = [objectCache objectForKey:manID];
					if ( theProfile == nil ) {
						theProfile = [ctrl insertNewPersonProfileWithID:manID isNew:&isNew];
						[objectCache setObject:theProfile forKey:manID];
					}
					if ( isNew ) {
						personIDOffset++;
						[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
						theProfile.name = [fromDict objectForKey:@"name"];
					}
					[lkSet addObject:theProfile];
				}
				[fbInfo addPeopleLike:lkSet];
			} else if ( [fbInfo.peopleLike count] ) {
				[fbInfo removePeopleLike:fbInfo.peopleLike];
			}
			// check comments
			otherDict = [vdoFeedDict objectForKey:@"comments"];
			if ( otherDict && [[otherDict objectForKey:@"count"] integerValue] ) {
				// someone has liked this video
				fbInfo.comments_count = [otherDict objectForKey:@"count"];
				// remove all comments and reinsert everything
				if ( [fbInfo.comments count] ) {
					[fbInfo setComments:nil];
				}
				NSArray * cmtAy = [otherDict objectForKey:@"data"];
				NSMutableSet * cmtSet = [NSMutableSet setWithCapacity:[cmtAy count]];
				NMFacebookComment * cmtObj;
				for (NSDictionary * cmtDict in cmtAy) {
					cmtObj = [ctrl insertNewFacebookComment];
					cmtObj.message = [cmtDict objectForKey:@"message"];
					cmtObj.created_time = [cmtDict objectForKey:@"created_time"];
					// look up the person
					fromDict = [cmtDict objectForKey:@"from"];
					manID = [fromDict objectForKey:@"id"];
					theProfile = [objectCache objectForKey:manID];
					if ( theProfile == nil ) {
						theProfile = [ctrl insertNewPersonProfileWithID:manID isNew:&isNew];
						[objectCache setObject:theProfile forKey:manID];
					}
					if ( isNew ) {
						personIDOffset++;
						[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
						theProfile.name = [fromDict objectForKey:@"name"];
					}
					cmtObj.fromPerson = theProfile;
					[cmtSet addObject:cmtObj];
				}
				[fbInfo addComments:cmtSet];
			} else if ( [fbInfo.comments count] ) {
				[fbInfo removeComments:fbInfo.comments];
			}
		}
	}
	// when first fire Facebook feed parsing task, feedDirectURLString is nil. This means we are getting the first page of a person's news feed. The newest item should always appear in the first page. Therefore, we only need to save the parsing time data under this condition.
	if ( _feedDirectURLString && maxUnixTime > [_channel.subscription.nm_since_id integerValue] ) {
		// update the last checked time
		_channel.subscription.nm_since_id = [NSString stringWithFormat:@"%d", maxUnixTime];
		time_t t;
		time(&t);
		_channel.subscription.nm_video_last_refresh = [NSNumber numberWithInteger:mktime(gmtime(&t))];
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
