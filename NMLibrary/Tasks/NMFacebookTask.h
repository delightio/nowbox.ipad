//
//  NMFacebookTask.h
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"
#import "FBConnect.h"

@class NMNetworkController;

@interface NMFacebookTask : NMTask

@property (nonatomic, retain) Facebook * facebook;

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl;
- (void)setParsedObjectsForResult:(id)result;

@end
