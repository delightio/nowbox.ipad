//
//  NMParseFacebookFeedTask.m
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseFacebookFeedTask.h"
#import "NMDataController.h"
#import "NMNetworkController.h"
#import "NMAccountManager.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "FBConnect.h"

static NSArray * youTubeRegexArray = nil;

@implementation NMParseFacebookFeedTask

@synthesize channel = _channel;
@synthesize nextPageURLString = _nextPageURLString;
@synthesize user_id = _user_id;
@synthesize profileArray = _profileArray;

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	command = NMCommandParseFacebookFeed;
	self.channel = chn;
	self.targetID = chn.nm_id;
	return self;
}

- (void)dealloc {
	[_user_id release];
	[_channel release];
	[_nextPageURLString release];
	[_profileArray release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	return [self.facebook requestWithGraphPath:@"me" andParams:[NSMutableDictionary dictionaryWithObject:@"feed" forKey:@"fields"] andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSArray * feedAy = [result valueForKeyPath:@"feed.data"];
	
	if ( feedAy == nil || [feedAy count] == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:[feedAy count]];
	NSString * extID = nil;
	NSString * dataType = nil;
	for (NSDictionary * theDict in feedAy) {
		// process the contents in the array
		dataType = [theDict objectForKey:@"type"];
		if ( [dataType isEqualToString:@"video"] || [dataType isEqualToString:@"link"] ) {
			extID = [NMParseFacebookFeedTask youTubeExternalIDFromLink:[theDict objectForKey:@"link"]];
			if ( extID ) {
				// we just need the external ID
				NSLog(@"video name: %@ %@", [theDict objectForKey:@"name"], extID);
				[parsedObjects addObject:extID];
			} else {
				NSLog(@"not added: %@ %@", [theDict objectForKey:@"name"], [theDict objectForKey:@"link"]);
			}
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
	NSUInteger c = [parsedObjects count];
	NSString * extID;
	NMVideo * vdo;
	BOOL isNew;
	NMPersonProfile * theProfile;
	NSDictionary * theDict;
	for (NSUInteger i = 0; i < c; i++) {
		extID = [parsedObjects objectAtIndex:i];
		// import the video
		vdo = [ctrl insertVideoIfExists:YES externalID:extID];
		theProfile = [ctrl insertNewPersonProfileWithID:[theDict objectForKey:@"nm_user_id"] isNew:&isNew];
		if ( isNew ) {
			vdo.personProfile = theProfile;
		}
	}
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
