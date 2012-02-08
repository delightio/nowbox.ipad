//
//  YouTubeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "YouTubeGridDataSource.h"

@implementation YouTubeGridDataSource

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    return self;
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
    return [dataController.subscribedChannels count];
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    ThumbnailView *view = (ThumbnailView *) [aGridView dequeueReusableSubview];
    
    if (!view) {
        view = [[[ThumbnailView alloc] init] autorelease];
        view.delegate = self.thumbnailViewDelegate;
    }
        
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;            
    NMChannel *channel = [dataController.subscribedChannels objectAtIndex:index];
    view.label.text = channel.title;
    [view.image setImageForChannel:channel];

    return view;
}

@end
