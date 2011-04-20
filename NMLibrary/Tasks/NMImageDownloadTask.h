//
//  NMImageDownloadTask.h
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMImageDownloadTask : NMTask {
	NSString * imageURLString;
	NMChannel * channel;
	NSHTTPURLResponse * httpResponse;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSHTTPURLResponse * httpResponse;

@end
