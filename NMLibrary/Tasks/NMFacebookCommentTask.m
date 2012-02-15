//
//  NMFacebookCommentTask.m
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FBConnect.h"
#import "NMFacebookCommentTask.h"
#import "NMFacebookInfo.h"
#import "NMFacebookComment.h"
#import "NMNetworkController.h"

NSString * const NMWillPostFacebookCommentNotification = @"NMWillPostFacebookCommentNotification";
NSString * const NMDidPostFacebookCommentNotification = @"NMDidPostFacebookCommentNotification";
NSString * const NMDidFailPostFacebookCommentNotification = @"NMDidFailPostFacebookCommentNotification";

NSString * const NMWillDeleteFacebookCommentNotification = @"NMWillDeleteFacebookCommentNotification";
NSString * const NMDidDeleteFacebookCommentNotification = @"NMDidDeleteFacebookCommentNotification";
NSString * const NMDidFailDeleteFacebookCommentNotification = @"NMDidFailDeleteFacebookCommentNotification";

@implementation NMFacebookCommentTask
@synthesize message = _message;
@synthesize objectID = _objectID;
@synthesize postInfo = _postInfo;

- (id)initWithInfo:(NMFacebookInfo *)info message:(NSString *)msg {
	self = [super init];
	command = NMCommandPostFacebookComment;
	self.message = msg;
	self.objectID = info.object_id;
	self.postInfo = info;
	return self;
}

- (id)initDeleteComment:(NMFacebookComment *)cmtObj {
	self = [super init];
	command = NMCommandDeleteFacebookComment;
	self.objectID = cmtObj.object_id;
	return self;
}

- (void)dealloc {
	[_postInfo release];
	[_objectID release];
	[_message release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	// use custom command index method
	idx = ABS((NSInteger)[_objectID hash]);
	return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	// we are liking a post. Not a comment in the post (well unless there's a feature requirement for that)
	if ( command == NMCommandPostFacebookComment ) {
		// here, _objectID stores the post's ID
		return [self.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/comments", _objectID] andParams:[NSMutableDictionary dictionaryWithObject:_message forKey:@"message"] andHttpMethod:@"POST" andDelegate:ctrl];
	}
	// delete comment
	return [self.facebook requestWithGraphPath:_objectID andParams:nil andHttpMethod:@"DELETE" andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSLog(@"%@", result);
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return NO;
}

- (NSString *)willLoadNotificationName {
	return command == NMCommandPostFacebookComment ? NMWillPostFacebookCommentNotification : NMWillDeleteFacebookCommentNotification;
}

- (NSString *)didLoadNotificationName {
	return command == NMCommandPostFacebookComment ? NMDidPostFacebookCommentNotification : NMDidDeleteFacebookCommentNotification;
}

- (NSString *)didFailNotificationName {
	return command == NMCommandPostFacebookComment ? NMDidFailPostFacebookCommentNotification : NMDidFailDeleteFacebookCommentNotification;
}

@end
