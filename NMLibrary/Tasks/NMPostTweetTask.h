//
//  NMPostTweetTask.h
//  ipad
//
//  Created by Bill So on 2/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@class NMVideo;
@class NMSocialComment;

@interface NMPostTweetTask : NMTask

@property (nonatomic, retain) ACAccount * account;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * tweetID;
@property (nonatomic, retain) NMSocialComment * comment;

// for retweet init with comment
- (id)initRetweetComment:(NMSocialComment *)cmt;
// to reply a tweet
- (id)initReplyWithComment:(NMSocialComment *)cmt;
// to send a new tweet (probably only for iPad version)
- (id)initPostComment:(NMSocialComment *)cmt;

@end
