//
//  NMURLConnection.h
//  ipad
//
//  Created by Bill So on 15/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NMTask;

@interface NMURLConnection : NSURLConnection

@property (nonatomic, assign) NMTask * task;

@end
