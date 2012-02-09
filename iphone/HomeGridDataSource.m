//
//  HomeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "HomeGridDataSource.h"
#import "YouTubeGridDataSource.h"

@implementation HomeGridDataSource

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    return [[[YouTubeGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext gridViewCellDelegate:self.gridViewCellDelegate] autorelease];
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    return 4;
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    PagingGridViewCell *view = (PagingGridViewCell *) [aGridView dequeueReusableCell];
    
    if (!view) {
        view = [[[PagingGridViewCell alloc] init] autorelease];
        view.delegate = self.gridViewCellDelegate;
    }
        
    switch (index) {
        case 0:
            view.label.text = @"Facebook";
            view.image.image = [UIImage imageNamed:@"social-facebook.png"];
            break;
        case 1:
            view.label.text = @"YouTube";
            view.image.image = [UIImage imageNamed:@"social-youtube.png"];
            break;
        case 2:
            view.label.text = @"Twitter";
            view.image.image = [UIImage imageNamed:@"social-twitter.png"];            
            break;
        case 3:
            view.label.text = @"Trending";
            view.image.image = [UIImage imageNamed:@"social-vimeo.png"];            
            break;
        default:
            break;
    }
    
    return view;
}

@end
