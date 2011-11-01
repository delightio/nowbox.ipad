//
//  NMCheckUpdateTask.h
//  ipad
//
//  Created by Bill So on 10/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@interface NMCheckUpdateTask : NMTask {
	NSString * deviceType;
	NSDictionary * versionDictionary;
}

@property (nonatomic, retain) NSDictionary * versionDictionary;

- (id)initWithDeviceType:(NSString *)devType;

@end
