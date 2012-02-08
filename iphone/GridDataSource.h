//
//  GridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagingGridView.h"
#import "ThumbnailView.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

@interface GridDataSource : NSObject <PagingGridViewDataSource>

@property (nonatomic, assign) id<ThumbnailViewDelegate> thumbnailViewDelegate;

- (id)initWithThumbnailViewDelegate:(id<ThumbnailViewDelegate>)thumbnailViewDelegate;
- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index;

@end
