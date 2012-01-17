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

static NSArray * youTubeRegexArray = nil;

@implementation NMParseFacebookFeedTask

@synthesize channel = _channel;
@synthesize facebook = _facebook;
@synthesize nextPageURLString = _nextPageURLString;

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
	NSString * extID = nil;
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		if ( [[theDict objectForKey:@"type"] isEqual:@"video"] ) {
			extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[theDict objectForKey:@"link"]];
			// we just need the external ID
			NSLog(@"video name: %@ %@", [theDict objectForKey:@"name"], extID);
			[parsedObjects addObject:extID];
		}
	}
	if ( [parsedObjects count] == 0 ) {
		[parsedObjects release];
		parsedObjects = nil;
	}
	self.nextPageURLString = [result valueForKeyPath:@"feed.data.paging.next"];
	NSLog(@"result %@", result);
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	// title, nm_session_id, external_id, type
	return YES;
}

+ (NSString *)youTubeExternalIDFromLink:(NSString *)urlStr {
	if ( urlStr == nil ) return NO;
	if ( youTubeRegexArray == nil ) {
		youTubeRegexArray = [[NSArray alloc] initWithObjects:
							 [NSRegularExpression regularExpressionWithPattern:@"youtube\\.com/watch\\?v=([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 [NSRegularExpression regularExpressionWithPattern:@"youtu\\.be/([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 [NSRegularExpression regularExpressionWithPattern:@"y2u\\.be/([\\w-]+)" options:NSRegularExpressionCaseInsensitive error:nil],
							 nil];
	}
	NSString * extID = nil;
	NSTextCheckingResult * result = nil;
	for (NSRegularExpression * regex in youTubeRegexArray) {
		result = [regex firstMatchInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])];
		if ( result && [result numberOfRanges] > 1) {
			extID = [urlStr substringWithRange:[result rangeAtIndex:1]];
			break;
		}
	}
	return extID;
}

@end
