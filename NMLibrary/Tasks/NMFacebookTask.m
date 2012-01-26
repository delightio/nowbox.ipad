//
//  NMFacebookTask.m
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"
#import "NMAccountManager.h"

@implementation NMFacebookTask
@synthesize facebook = _facebook;

- (id)init {
	self = [super init];
	self.facebook = [NMAccountManager sharedAccountManager].facebook;
	return self;
}

- (void)dealloc {
	[_facebook release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	return nil;
}

- (void)setParsedObjectsForResult:(id)result {
	
}

@end
