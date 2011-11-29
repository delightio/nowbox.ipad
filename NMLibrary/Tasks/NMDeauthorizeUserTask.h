//
//  NMDeauthorizeUserTask.h
//  ipad
//
//  Created by Bill So on 10/16/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@interface NMDeauthorizeUserTask : NMTask {
	NSDictionary * userDictionary;
}

@property (nonatomic, retain) NSDictionary * userDictionary;

- (id)initForYouTube;

@end
