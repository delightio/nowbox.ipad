//
//  GridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridDataSource.h"

@implementation GridDataSource

@synthesize thumbnailViewDelegate;

- (id)initWithThumbnailViewDelegate:(id<ThumbnailViewDelegate>)aThumbnailViewDelegate
{
    self = [super init];
    if (self) {
        thumbnailViewDelegate = aThumbnailViewDelegate;
    }
    return self;
}

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    // To be overriden by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    // To be overriden by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    // To be overriden by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
