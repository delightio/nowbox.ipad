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
#import "NMSocialInfo.h"
#import "NMSocialComment.h"
#import "FBConnect.h"
#import "NMObjectCache.h"

NSString * const NMWillParseFacebookFeedNotification = @"NMWillParseFacebookFeedNotification";
NSString * const NMDidParseFacebookFeedNotification = @"NMDidParseFacebookFeedNotification";
NSString * const NMDidFailParseFacebookFeedNotification = @"NMDidFailParseFacebookFeedNotification";

NSString * const NMDidGetNewPersonProfileNotification = @"NMDidGetNewPersonProfileNotification";

static NSArray * youTubeRegexArray = nil;

@implementation NMParseFacebookFeedTask

@synthesize channel = _channel;
@synthesize nextPageURLString = _nextPageURLString;
@synthesize user_id = _user_id;
@synthesize since_id = _since_id;
@synthesize feedDirectURLString = _feedDirectURLString;
@synthesize facebookTypeNumber = _facebookTypeNumber;
@synthesize notifyOnNewProfile = _notifyOnNewProfile;

- (id)initWithChannel:(NMChannel *)chn {
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"Getting first page - Facebook - %@", chn.title);
#endif
	self = [super init];
	command = NMCommandParseFacebookFeed;
	self.channel = chn;
	self.since_id = chn.subscription.nm_since_id;
	if ( _since_id == nil || [_since_id isEqualToString:@""]) self.since_id = @"0";
	NMPersonProfile * theProfile =  chn.subscription.personProfile;
	self.user_id = theProfile.nm_user_id;
	isAccountOwner = [theProfile.nm_relationship_type integerValue] == NMRelationshipMe;
	self.targetID = chn.nm_id;
	return self;
}

- (id)initWithChannel:(NMChannel *)chn taskInfo:(NSDictionary *)infoDict {
	self = [super init];
	
	command = NMCommandParseFacebookFeed;
	self.feedDirectURLString = [infoDict objectForKey:@"next_url"];
	numberOfIterations = [[infoDict objectForKey:@"iteration"] integerValue] + 1;
	self.channel = chn;
	NMPersonProfile * theProfile =  chn.subscription.personProfile;
	self.user_id = theProfile.nm_user_id;
	isAccountOwner = [theProfile.nm_relationship_type integerValue] == NMRelationshipMe;
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
	isAccountOwner = [theProfile.nm_relationship_type integerValue] == NMRelationshipMe;
	self.targetID = chn.nm_id;
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"Getting next page - Facebook");
#endif
	
	return self;
}

- (void)dealloc {
	[_user_id release];
	[_since_id release];
	[_channel release];
	[_nextPageURLString release];
	[_feedDirectURLString release];
	[_facebookTypeNumber release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	// use custom command index method
	idx = ABS((NSInteger)[_user_id hash]);
	return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
}

- (NSNumber *)facebookTypeNumber {
	if ( _facebookTypeNumber == nil ) {
		_facebookTypeNumber = [[NSNumber numberWithInteger:NMChannelUserFacebookType] retain];
	}
	return _facebookTypeNumber;
}

- (void)setupPersonProfile:(NMPersonProfile *)theProfile withID:(NSInteger)theID {
	theProfile.nm_id = [NSNumber numberWithInteger:theID];
	theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
	theProfile.nm_error = [NSNumber numberWithInteger:NMErrorPendingImport];
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
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"received facebook feed - %d", feedCount);
#endif

	if ( feedCount == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:feedCount];
	NSString * extID = nil;
	NSString * dataType = nil;
	NSString * msgStr = nil;
	NSInteger theTime;
	NSDictionary * otherDict;
	NSMutableDictionary * vdoDict = nil;
	NSArray * theActions;
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		dataType = [theDict objectForKey:@"type"];
		if ( [dataType isEqualToString:@"video"] || [dataType isEqualToString:@"link"] ) {
			extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[theDict objectForKey:@"link"]];
			if ( extID && (theActions = [theDict objectForKey:@"actions"]) ) {
				vdoDict = [NSMutableDictionary dictionaryWithCapacity:4];
				// we just need the external ID
				[vdoDict setObject:extID forKey:@"external_id"];
				msgStr = [theDict objectForKey:@"message"];
				if ( msgStr ) [vdoDict setObject:msgStr forKey:@"message"];
				[vdoDict setObject:[theDict objectForKey:@"id"] forKey:@"object_id"];
				[vdoDict setObject:[theDict objectForKey:@"created_time"] forKey:@"created_time"];
				theTime = [[theDict objectForKey:@"updated_time"] integerValue];
				[vdoDict setObject:[theDict objectForKey:@"updated_time"] forKey:@"updated_time"];
				
				otherDict = [theDict objectForKey:@"likes"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"likes"];
				
				otherDict = [theDict objectForKey:@"comments"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"comments"];
				
				otherDict = [theDict objectForKey:@"from"];
				if ( otherDict ) [vdoDict setObject:otherDict forKey:@"from"];
				
				// action URLs
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
	NSNumber * errNum = [NSNumber numberWithInteger:NMErrorPendingImport];
	// enumerate the feed
	NSInteger idx = -1;
	NSInteger personIDOffset = 0;
	NMSocialInfo * fbInfo;
	NMConcreteVideo * conVdo = nil;
	NMVideo * vdo = nil;
	NSString * extID;
	
	NSNumber * friendRelNum = [NSNumber numberWithInteger:NMRelationshipFriend];
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	
	for (NSDictionary * vdoFeedDict in parsedObjects) {
		extID = [vdoFeedDict objectForKey:@"external_id"];
		idx++;
		fbInfo = nil;
		NMVideoExistenceCheckResult chkResult = [ctrl videoExistsWithExternalID:extID channel:_channel targetVideo:&conVdo];
#ifdef DEBUG_FACEBOOK_IMPORT
		NSLog(@"import check result: %@ %d", [vdoFeedDict objectForKey:@"external_id"], chkResult);
#endif
		switch (chkResult) {
			case NMVideoExistsButNotInChannel:
			{
				numberOfVideoAdded++;
				// create only the NMVideo object
				vdo = [ctrl insertNewVideo];
				vdo.channel = _channel;
				vdo.nm_session_id = NM_SESSION_ID;
				// sort order of video == date when the video was posted
				vdo.nm_sort_order = [vdoFeedDict objectForKey:@"created_time"];
				vdo.video = conVdo;
				// check if the set contains the info from this person already
				NSSet * fbMtnSet = conVdo.socialMentions;
				BOOL postFound = NO;
				for (fbInfo in fbMtnSet) {
					if ( [fbInfo.nm_type integerValue] == NMChannelUserFacebookType && [fbInfo.object_id isEqualToString:[vdoFeedDict objectForKey:@"object_id"]] ) {
						postFound = YES;
						break;
					}
				}
				if ( !postFound ) {
					// create facebook info
					fbInfo = [ctrl insertNewSocialInfo];
					fbInfo.video = vdo.video;
					fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
					// set the link
					fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
					fbInfo.comment_post_url = [vdoFeedDict objectForKey:@"comment_post_url"];
					fbInfo.like_post_url = [vdoFeedDict objectForKey:@"like_post_url"];
					fbInfo.message = [vdoFeedDict objectForKey:@"message"];
					fbInfo.nm_date_last_updated = [vdoFeedDict objectForKey:@"updated_time"];
					fbInfo.nm_date_posted = [vdoFeedDict objectForKey:@"created_time"];
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
				vdo.nm_session_id = NM_SESSION_ID;
				vdo.nm_sort_order = [vdoFeedDict objectForKey:@"created_time"];
				// create facebook info
				fbInfo = [ctrl insertNewSocialInfo];
				fbInfo.video = conVdo;
				fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
				// set the link
				fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
				fbInfo.comment_post_url = [vdoFeedDict objectForKey:@"comment_post_url"];
				fbInfo.like_post_url = [vdoFeedDict objectForKey:@"like_post_url"];
				fbInfo.message = [vdoFeedDict objectForKey:@"message"];
				fbInfo.nm_date_last_updated = [vdoFeedDict objectForKey:@"updated_time"];
				fbInfo.nm_date_posted = [vdoFeedDict objectForKey:@"created_time"];
				break;
				
			case NMVideoExistsAndInChannel:
			{
				// update sort order
				vdo.nm_session_id = NM_SESSION_ID;
				// update for mentions
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
					fbInfo.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
					// set the link
					fbInfo.object_id = [vdoFeedDict objectForKey:@"object_id"];
					fbInfo.comment_post_url = [vdoFeedDict objectForKey:@"comment_post_url"];
					fbInfo.like_post_url = [vdoFeedDict objectForKey:@"like_post_url"];
					fbInfo.message = [vdoFeedDict objectForKey:@"message"];
					fbInfo.nm_date_last_updated = [vdoFeedDict objectForKey:@"updated_time"];
					fbInfo.nm_date_posted = [vdoFeedDict objectForKey:@"created_time"];
				} // else - object clean up will be done later below.
				break;
			}
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
					theProfile = [ctrl insertNewPersonProfileWithID:manID type:self.facebookTypeNumber isNew:&isNew];
					if ( isNew ) {
						[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
						theProfile.name = [fromDict objectForKey:@"name"];
					}
					[objectCache setObject:theProfile forKey:manID];
				}
				if ( isAccountOwner && (isNew || [theProfile.nm_relationship_type integerValue] != NMRelationshipFriend ) ) {
					// encounter a new profile when parsing my own News Feed
					if ( ![manID isEqualToString:_user_id] ) {
						theProfile.nm_relationship_type = friendRelNum;
					}
					if ( _notifyOnNewProfile ) {
						[nc postNotificationName:NMDidGetNewPersonProfileNotification object:theProfile];
					}
				}
				// set who posted this video
				fbInfo.poster = theProfile;
			}
			// check likes
			NSDictionary * otherDict = [vdoFeedDict objectForKey:@"likes"];
			if ( otherDict && [[otherDict objectForKey:@"count"] integerValue] ) {
				// there are some comments in this video. add the comment
				fbInfo.likes_count = [otherDict objectForKey:@"count"];
				// remove all existing relationship and reinsert new ones
				if ( [fbInfo.peopleLike count] ) {
					[fbInfo removePeopleLike:fbInfo.peopleLike];
				}
				NSArray * lkAy = [otherDict objectForKey:@"data"];
				NSMutableSet * lkSet = [NSMutableSet setWithCapacity:[lkAy count]];
				for (fromDict in lkAy) {
					manID = [fromDict objectForKey:@"id"];
					theProfile = [objectCache objectForKey:manID];
					if ( theProfile == nil ) {
						theProfile = [ctrl insertNewPersonProfileWithID:manID type:self.facebookTypeNumber isNew:&isNew];
						[objectCache setObject:theProfile forKey:manID];
					}
					if ( isNew ) {
						personIDOffset++;
						[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
						theProfile.name = [fromDict objectForKey:@"name"];
					}
					[lkSet addObject:theProfile];
				}
#ifdef DEBUG_FACEBOOK_IMPORT
				NSLog(@"add like: %@", theProfile.name);
#endif
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
					[fbInfo removeComments:fbInfo.comments];
				}
				NSArray * cmtAy = [otherDict objectForKey:@"data"];
				NSMutableSet * cmtSet = [NSMutableSet setWithCapacity:[cmtAy count]];
				NMSocialComment * cmtObj;
				NSNumber * lastTimeNum = nil;
				for (NSDictionary * cmtDict in cmtAy) {
					cmtObj = [ctrl insertNewSocialComment];
					cmtObj.message = [cmtDict objectForKey:@"message"];
					cmtObj.created_time = [cmtDict objectForKey:@"created_time"];
					cmtObj.object_id = [cmtDict objectForKey:@"id"];
					if ( lastTimeNum == nil || [cmtObj.created_time compare:lastTimeNum] == NSOrderedDescending ) {
						lastTimeNum = cmtObj.created_time;
					}
					// look up the person
					fromDict = [cmtDict objectForKey:@"from"];
					manID = [fromDict objectForKey:@"id"];
					theProfile = [objectCache objectForKey:manID];
					if ( theProfile == nil ) {
						theProfile = [ctrl insertNewPersonProfileWithID:manID type:self.facebookTypeNumber isNew:&isNew];
						[objectCache setObject:theProfile forKey:manID];
					}
					if ( isNew ) {
						personIDOffset++;
						[self setupPersonProfile:theProfile withID:personIDBase + personIDOffset];
						theProfile.name = [fromDict objectForKey:@"name"];
					}
					cmtObj.fromPerson = theProfile;
#ifdef DEBUG_FACEBOOK_IMPORT
					NSLog(@"add comment: %@", cmtObj.message);
#endif
					[cmtSet addObject:cmtObj];
				}
				[fbInfo addComments:cmtSet];
				fbInfo.nm_date_last_updated = lastTimeNum;
			} else if ( [fbInfo.comments count] ) {
				[fbInfo removeComments:fbInfo.comments];
			}
		}
	}
	if ( numberOfVideoAdded && [_channel.subscription.nm_hidden boolValue] ) {
		_channel.subscription.nm_hidden = (NSNumber *)kCFBooleanFalse;
	}
	// when first fire Facebook feed parsing task, feedDirectURLString is nil. This means we are getting the first page of a person's news feed. The newest item should always appear in the first page. Therefore, we only need to save the parsing time data under this condition.
	if ( _feedDirectURLString == nil && maxUnixTime > [_channel.subscription.nm_since_id integerValue] ) {
		// update the last checked time
		_channel.subscription.nm_since_id = [NSString stringWithFormat:@"%d", maxUnixTime];
	}
	_channel.subscription.nm_video_last_refresh = [NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]];
	[objectCache release];
	return YES;
}

+ (NSString *)youTubeExternalIDFromLink:(NSString *)urlStr {
	if ( urlStr == nil || (id)urlStr == [NSNull null] ) return NO;
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
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"Facebook feed: video added: %d", numberOfVideoAdded);
#endif
	_channel.video_count = [NSNumber numberWithUnsignedInteger:[_channel.videos count]];
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_received", [NSNumber numberWithUnsignedInteger:numberOfVideoAdded], @"num_video_added", _channel, @"channel", _nextPageURLString, @"next_url", [NSNumber numberWithInteger:numberOfIterations], @"iteration", nil];
}

@end
