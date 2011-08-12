//
//  NMGetCategoriesTask.h
//  ipad
//
//  Created by Bill So on 8/8/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@interface NMGetCategoriesTask : NMTask {
	NSMutableIndexSet * serverCategoryIDIndexSet;
	NSMutableDictionary * categoryDictionary;
}

@end
