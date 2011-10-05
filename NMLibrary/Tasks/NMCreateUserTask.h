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
}

@property (nonatomic, retain) NSURL * verificationURL;

- (id)initTwitterVerificationWithURL:(NSURL *)aURL;
- (id)initFacebookVerificationWithURL:(NSURL *)aURL;

@end
