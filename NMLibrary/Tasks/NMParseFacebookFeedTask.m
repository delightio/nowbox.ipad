//
//  NMParseFacebookFeedTask.m
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseFacebookFeedTask.h"
#import "NMNetworkController.h"
#import "NMChannel.h"
#import "FBConnect.h"

static NSRegularExpression * youtubeLinkRegExp = nil;

@implementation NMParseFacebookFeedTask

@synthesize channel = _channel;
@synthesize facebook = _facebook;
@synthesize nextPageURLString = _nextPageURLString;

+ (void)initialize {
	youtubeLinkRegExp = [[NSRegularExpression alloc] initWithPattern:@"\\youtube\\.com/watch\\" options:NSRegularExpressionCaseInsensitive error:nil];
}

- (id)initWithChannel:(NMChannel *)chn facebookProxy:(Facebook *)fbObj {
	self = [super init];
	command = NMCommandParseFacebookFeed;
	self.facebook = fbObj;
	self.channel = chn;
	self.targetID = chn.nm_id;
	return self;
}

- (void)dealloc {
	[_channel release];
	[_facebook release];
	[_nextPageURLString release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	return [_facebook requestWithGraphPath:@"me" andParams:[NSMutableDictionary dictionaryWithObject:@"feed" forKey:@"fields"] andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSArray * feedAy = [result valueForKeyPath:@"feed.data"];
	
	if ( feedAy == nil || [feedAy count] == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:[feedAy count]];
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		if ( [[theDict objectForKey:@"type"] isEqual:@"video"] && [self isYouTubeLink:[theDict objectForKey:@"link"]] ) {
			// this is a youtube link. we should do sth
			[parsedObjects addObject:theDict];
		}
	}
	self.nextPageURLString = [result valueForKeyPath:@"feed.data.paging.next"];
	NSLog(@"result %@", result);
}

- (void)processDownloadedDataInBuffer {
	
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return YES;
}

- (BOOL)isYouTubeLink:(NSString *)urlStr {
	if ( urlStr == nil ) return NO;
	return [youtubeLinkRegExp numberOfMatchesInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])] > 0;
}

@end
