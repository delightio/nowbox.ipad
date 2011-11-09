//
//  NMCreateUserTask.h
//  ipad
//
//  Created by Bill So on 7/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

/*!
 Handles 2 situations:
 * create new user, or
 * verify a user after logged in
 */

@interface NMCreateUserTask : NMTask {
	NSURL * verificationURL;
	NSString * email;
	NSDictionary * userDictionary;
}

@property (nonatomic, retain) NSURL * verificationURL;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSDictionary * userDictionary;

- (id)initTwitterVerificationWithURL:(NSURL *)aURL;
- (id)initFacebookVerificationWithURL:(NSURL *)aURL;
- (id)initYoutubeVerificationWithURL:(NSURL *)aURL;

@end
