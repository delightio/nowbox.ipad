//
//  NMFacebookCommentTask.m
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FBConnect.h"
#import "NMFacebookCommentTask.h"
#import "NMSocialInfo.h"
#import "NMSocialComment.h"
#import "NMConcreteVideo.h"
#import "NMPersonProfile.h"
#import "NMNetworkController.h"
#import "NMAccountManager.h"

NSString * const NMWillPostNewFacebookLinkNotification = @"NMWillPostNewFacebookLinkNotification";
NSString * const NMDidPostNewFacebookLinkNotification = @"NMDidPostNewFacebookLinkNotification";
NSString * const NMDidFailPostNewFacebookLinkNotification = @"NMDidFailPostNewFacebookLinkNotification";

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
@synthesize externalID = _externalID;

- (id)initWithInfo:(NMSocialInfo *)info message:(NSString *)msg {
	self = [super init];
	if ( info.object_id == nil ) {
		// make a new share on Facebook
		command = NMCommandPostNewFacebookLink;
		self.objectID = [NMAccountManager sharedAccountManager].facebookProfile.nm_user_id;
	} else {
		// comment to an existing Facebook post
		command = NMCommandPostFacebookComment;
		self.objectID = info.object_id;
	}
	self.message = msg;
	self.postInfo = info;
	self.externalID = info.video.external_id;
	return self;
}

- (id)initDeleteComment:(NMSocialComment *)cmtObj {
	self = [super init];
	command = NMCommandDeleteFacebookComment;
	self.objectID = cmtObj.object_id;
	return self;
}

- (void)dealloc {
	[_postInfo release];
	[_objectID release];
	[_message release];
	[_externalID release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	// use custom command index method
	switch (command) {
		case NMCommandPostNewFacebookLink:
			idx = (NSInteger)ABS([_message hash]);
			break;
		default:
			idx = (NSInteger)ABS([_objectID hash]);
			break;
	}
	return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	// we are liking a post. Not a comment in the post (well unless there's a feature requirement for that)
	switch (command) {
		case NMCommandPostFacebookComment:
			return [self.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/comments", _objectID] andParams:[NSMutableDictionary dictionaryWithObject:_message forKey:@"message"] andHttpMethod:@"POST" andDelegate:ctrl];
			break;
			
		case NMCommandPostNewFacebookLink:
			return [self.facebook requestWithGraphPath:[NSString stringWithFormat:@"%@/links", _objectID] andParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSString stringWithFormat:@"http://youtu.be/%@", _externalID], @"link", nil] andHttpMethod:@"POST" andDelegate:ctrl];
			break;
			
		case NMCommandDeleteFacebookComment:
			// delete comment
			return [self.facebook requestWithGraphPath:_objectID andParams:nil andHttpMethod:@"DELETE" andDelegate:ctrl];
			break;
			
		default:
			break;
	}
	return nil;
}

- (void)setParsedObjectsForResult:(id)result {
	if ( command == NMCommandPostNewFacebookLink && _postInfo.object_id == nil ) {
		// if info object is new, update the Facebook info
		NSString * idStr = [result objectForKey:@"id"];
		_postInfo.object_id = idStr;
		_postInfo.comment_post_url = [NSString stringWithFormat:@"http://www.facebook.com/%@/posts/%@", _objectID, idStr];
		_postInfo.like_post_url = [NSString stringWithFormat:@"http://www.facebook.com/%@/posts/%@", _objectID, idStr];
		_postInfo.comments_count = (NSNumber *)kCFBooleanTrue;
		_postInfo.nm_date_last_updated = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return YES;
}

- (NSString *)willLoadNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandPostNewFacebookLink:
			str = NMWillPostNewFacebookLinkNotification;
			break;
		case NMCommandPostFacebookComment:
			str = NMWillPostFacebookCommentNotification;
			break;
		case NMCommandDeleteFacebookComment:
			str = NMWillDeleteFacebookCommentNotification;
			break;
			
		default:
			break;
	}
	return str;
}

- (NSString *)didLoadNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandPostNewFacebookLink:
			str = NMDidPostNewFacebookLinkNotification;
			break;
		case NMCommandPostFacebookComment:
			str = NMDidPostFacebookCommentNotification;
			break;
		case NMCommandDeleteFacebookComment:
			str = NMDidDeleteFacebookCommentNotification;
			break;
			
		default:
			break;
	}
	return str;
}

- (NSString *)didFailNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandPostNewFacebookLink:
			str = NMDidFailPostNewFacebookLinkNotification;
			break;
		case NMCommandPostFacebookComment:
			str = NMDidFailPostFacebookCommentNotification;
			break;
		case NMCommandDeleteFacebookComment:
			str = NMDidFailDeleteFacebookCommentNotification;
			break;
			
		default:
			break;
	}
	return str;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:_postInfo forKey:@"socialInfo"];
}

@end
