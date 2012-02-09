//
//  GridViewController.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridViewController.h"
#import "HomeGridDataSource.h"
#import "YouTubeGridDataSource.h"

#define kRearrangePageSwitchDistance 50
#define kRearrangePageSwitchDuration 1.0

@implementation GridViewController

@synthesize gridView;
@synthesize pageControl;
@synthesize gridDataSource;
@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.managedObjectContext = aManagedObjectContext;
    }
    return self;
}

- (void)dealloc
{
    [rearrangePageSwitchTimer invalidate];
    
    [gridView release];
    [pageControl release];
    [gridDataSource release];
    [managedObjectContext release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pageControl.numberOfPages = gridView.numberOfPages;
    
    self.gridDataSource = [[[HomeGridDataSource alloc] initWithGridView:gridView managedObjectContext:managedObjectContext thumbnailViewDelegate:self] autorelease];
    gridView.dataSource = gridDataSource;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.gridView = nil;
    self.gridDataSource = nil;
    self.pageControl = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)searchButtonPressed:(id)sender
{
    
}

- (IBAction)refreshButtonPressed:(id)sender
{
    
}

- (IBAction)settingsButtonPressed:(id)sender
{
    
}

#pragma mark - PagingGridViewDelegate

- (void)gridViewDidScroll:(PagingGridView *)aGridView
{
    if (!scrollingToPage) {
        NSUInteger currentPage = MAX(0, round(aGridView.contentOffset.x / aGridView.frame.size.width));
        [pageControl setCurrentPage:currentPage];
    }
}

- (void)gridViewWillBeginDragging:(PagingGridView *)gridView
{
    scrollingToPage = NO;
}

- (void)gridViewDidEndScrollingAnimation:(PagingGridView *)gridView
{
    scrollingToPage = NO;
}

#pragma mark - CustomPageControlDelegate

- (BOOL)pageControl:(CustomPageControl *)pageControl shouldSelectPageAtIndex:(NSUInteger)index
{
    return !scrollingToPage;
}

- (void)pageControl:(CustomPageControl *)pageControl didSelectPageAtIndex:(NSUInteger)index
{
    scrollingToPage = YES;
    [gridView setContentOffset:CGPointMake(index * gridView.frame.size.width, 0) animated:YES];
}

#pragma mark - ThumbnailViewDelegate

- (void)thumbnailViewDidTap:(ThumbnailView *)thumbnailView
{
    NSUInteger index = thumbnailView.tag;
    self.gridDataSource = [gridDataSource nextDataSourceForIndex:index];
    gridView.dataSource = gridDataSource;
    pageControl.numberOfPages = gridView.numberOfPages;
}

- (void)thumbnailViewDidBeginRearranging:(ThumbnailView *)thumbnailView
{
    gridView.scrollEnabled = NO;
    gridDataSource.updatesEnabled = NO;
    thumbnailView.lastDragLocation = CGPointMake(thumbnailView.center.x - gridView.contentOffset.x, thumbnailView.center.y - gridView.contentOffset.y);
}

- (void)thumbnailViewDidEndRearranging:(ThumbnailView *)thumbnailView
{
    NSUInteger index = thumbnailView.tag;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         thumbnailView.frame = [gridView frameForIndex:index];
                     }
                     completion:^(BOOL finished){
                         gridView.scrollEnabled = YES;     
                         gridDataSource.updatesEnabled = YES;
                     }];
}

- (void)rearrangePageSwitchTimerFired:(NSTimer *)timer
{
    rearrangePageSwitchTimer = nil;
    CGPoint touchLocation = [[[timer userInfo] objectForKey:@"touchLocation"] CGPointValue];
    if (touchLocation.x - gridView.contentOffset.x < kRearrangePageSwitchDistance && gridView.currentPage > 0) {
        // Switch page left
        gridView.currentPage = gridView.currentPage - 1;
    } else if (touchLocation.x - gridView.contentOffset.x > gridView.frame.size.width - kRearrangePageSwitchDistance && gridView.currentPage + 1 < gridView.numberOfPages) {
        // Switch page right
        gridView.currentPage = gridView.currentPage + 1;    
    }
}

- (void)thumbnailView:(ThumbnailView *)thumbnailView didDragToCenter:(CGPoint)center touchLocation:(CGPoint)touchLocation
{        
    thumbnailView.lastDragLocation = CGPointMake(center.x - gridView.contentOffset.x, center.y - gridView.contentOffset.y);
    
    if ((touchLocation.x - gridView.contentOffset.x < kRearrangePageSwitchDistance && gridView.currentPage > 0) || 
        (touchLocation.x - gridView.contentOffset.x > gridView.frame.size.width - kRearrangePageSwitchDistance && gridView.currentPage + 1 < gridView.numberOfPages)) {
        // Close to left or right edge and page switch possible
        if (!rearrangePageSwitchTimer) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithCGPoint:touchLocation] forKey:@"touchLocation"];
            rearrangePageSwitchTimer = [NSTimer scheduledTimerWithTimeInterval:kRearrangePageSwitchDuration target:self selector:@selector(rearrangePageSwitchTimerFired:) userInfo:userInfo repeats:NO];
        }
        
    } else {    
        if (rearrangePageSwitchTimer) {
            // Cancel any pending page switch action - we moved away from the edge
            [rearrangePageSwitchTimer invalidate];
            rearrangePageSwitchTimer = nil;
        }
        
        // Reposition the view
        NSUInteger oldIndex = thumbnailView.tag;
        NSInteger newIndex = [gridView repositioningIndexForFrame:thumbnailView.frame];
        
        if (newIndex != oldIndex && newIndex >= 0) {
            [gridView repositionView:thumbnailView fromIndex:oldIndex toIndex:newIndex animated:YES];
            [gridDataSource moveObjectAtIndex:oldIndex toIndex:newIndex];
        }
    }
}

@end
