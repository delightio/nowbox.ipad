//
//  NMOpenGraphSubscribeTask.m
//  ipad
//
//  Created by Bill So on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMOpenGraphSubscribeTask.h"
#import "NMNetworkController.h"
#import "NMChannel.h"

@implementation NMOpenGraphSubscribeTask

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	command = NMCommandPostOpenGraphSubscribe;
	self.targetID = chn.nm_id;
	return self;
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	return [self.facebook requestWithGraphPath:@"me" andParams:[NSMutableDictionary dictionaryWithObject:@"channel URL" forKey:@"channel"] andHttpMethod:@"POST" andDelegate:ctrl];
}

@end
