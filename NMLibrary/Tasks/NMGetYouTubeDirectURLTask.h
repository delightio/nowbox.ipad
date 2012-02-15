//
//  NMGetYouTubeDirectURLTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMVideo;
@class NMConcreteVideo;

@interface NMGetYouTubeDirectURLTask : NMTask {
	NMVideo * video;
	NMConcreteVideo * concreteVideo;
	NSString * externalID;
	NSString * directURLString;
	NSString * directSDURLString;
	NSInteger expiryTime;
	NSMutableDictionary * authorDict;
	NSMutableDictionary * videoInfoDict;
	NSNumberFormatter * viewCountFormatter;
	NSDateFormatter * timeCreatedFormatter;
}

@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NMConcreteVideo * concreteVideo;
@property (nonatomic, retain) NSString * externalID;
@property (nonatomic, retain) NSString * directURLString;
@property (nonatomic, retain) NSString * directSDURLString;
@property (nonatomic, retain) NSMutableDictionary * authorDict;
@property (nonatomic, retain) NSMutableDictionary * videoInfoDict;

- (id)initWithVideo:(NMVideo *)vdo;
- (id)initImportVideo:(NMConcreteVideo *)vdo;
- (id)dateFromTimeCreatedString:(NSString *)dateStr;
- (id)numberFromViewCountString:(NSString *)cntStr;

@end
