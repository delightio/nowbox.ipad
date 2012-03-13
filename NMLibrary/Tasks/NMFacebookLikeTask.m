//
//  NMFacebookLikeTask.m
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FBConnect.h"
#import "NMFacebookLikeTask.h"
#import "NMSocialInfo.h"
#import "NMNetworkController.h"
#import "NMDataController.h"

NSString * const NMWillPostFacebookLikeNotification = @"NMWillPostFacebookLikeNotification";
NSString * const NMDidPostFacebookLikeNotificaiton = @"NMDidPostFacebookLikeNotificaiton";
NSString * const NMDidFailPostFacebookLikeNotificaiton = @"NMDidFailPostFacebookLikeNotificaiton";

NSString * const NMWillDeleteFacebookLikeNotification = @"NMWillDeleteFacebookLikeNotification";
NSString * const NMDidDeleteFacebookLikeNotification = @"NMDidDeleteFacebookLikeNotification";
NSString * const NMDidFailDeleteFacebookLikeNotification = @"NMDidFailDeleteFacebookLikeNotification";

@implementation NMFacebookLikeTask
@synthesize postInfo = _postInfo;
@synthesize objectID = _objectID;

- (id)initWithInfo:(NMSocialInfo *)info like:(BOOL)aLike {
	self = [super init];
	command = aLike ? NMCommandPostFacebookLike : NMCommandDeleteFacebookLike;
	self.postInfo = info;
	self.objectID = info.object_id;
	return self;
}

- (void)dealloc {
	[_postInfo release];
	[_objectID release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	// use custom command index method
	idx = ABS((NSInteger)[_objectID hash]);
	return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	NSString * gpath = [NSString stringWithFormat:@"%@/likes", _objectID];
	return [self.facebook requestWithGraphPath:gpath andParams:[NSMutableDictionary dictionary] andHttpMethod:command == NMCommandPostFacebookLike ? @"POST" : @"DELETE" andDelegate:ctrl];
}

//- (void)setParsedObjectsForResult:(id)result {
//}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( command == NMCommandPostFacebookLike ) {
		// you like this video
		[_postInfo addPeopleLikeObject:[ctrl myFacebookProfile]];
	} else {
		[_postInfo removePeopleLikeObject:[ctrl myFacebookProfile]];
	}
	return NO;
}

- (NSString *)willLoadNotificationName {
	return command == NMCommandPostFacebookLike ? NMWillPostFacebookLikeNotification : NMWillDeleteFacebookLikeNotification;
}

- (NSString *)didLoadNotificationName {
	return command == NMCommandPostFacebookLike ? NMDidPostFacebookLikeNotificaiton : NMDidDeleteFacebookLikeNotification;
}

- (NSString *)didFailNotificationName {
	return command == NMCommandPostFacebookLike ? NMDidFailPostFacebookLikeNotificaiton : NMDidFailDeleteFacebookLikeNotification;
}

@end
