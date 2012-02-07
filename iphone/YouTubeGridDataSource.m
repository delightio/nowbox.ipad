//
//  YouTubeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "YouTubeGridDataSource.h"

@implementation YouTubeGridDataSource

- (GridDataSource *)dataSourceForIndex:(NSUInteger)index
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
        [view.button addTarget:aGridView action:@selector(itemSelected:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    view.button.tag = index;
    
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;            
    NMChannel *channel = [dataController.subscribedChannels objectAtIndex:index];
    view.label.text = channel.title;
    [view.image setImageForChannel:channel];

    return view;
}

@end
