//
//  NMTokenTask.h
//  ipad
//
//  Created by Bill So on 11/5/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@interface NMTokenTask : NMTask {
	NSString * secret;
}

@property (nonatomic, retain) NSString * secret;

- (id)initGetToken;
//- (id)initTestToken;

@end
