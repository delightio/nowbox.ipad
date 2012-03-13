//
//  NMOpenGraphWatchTask.m
//  ipad
//
//  Created by Bill So on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMOpenGraphWatchTask.h"
#import "NMNetworkController.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"

@implementation NMOpenGraphWatchTask
@synthesize externalID = _externalID;
@synthesize startTime = _startTime;

- (id)initForVideo:(NMVideo *)vdo playsVideo:(BOOL)aflag {
	self = [super init];
	command = NMCommandPostOpenGraphWatch;
	isPlayingVideo = aflag;
	self.targetID = vdo.video.nm_id;
	self.externalID = vdo.video.external_id;
	return self;
}

- (void)dealloc {
	[_externalID release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", _externalID], @"video"/*, [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]], isPlayingVideo ? @"start_time" : @"end_time"*/, nil];
	return [self.facebook requestWithGraphPath:@"me/video.watches" andParams:dict andHttpMethod:@"POST" andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSLog(@"graph result %@", result);
}

@end
