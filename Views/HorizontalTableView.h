
#import <UIKit/UIKit.h>

@class HorizontalTableView;
@class PanelVideoContainerView;
@class VideoRowController;

@protocol HorizontalTableViewDelegate

- (NSInteger)numberOfColumnsForTableView:(HorizontalTableView *)tableView;
- (PanelVideoContainerView *)tableView:(HorizontalTableView *)tableView viewForIndex:(NSInteger)index;
- (CGFloat)columnWidthForTableView:(HorizontalTableView *)tableView;

@end

@protocol HorizontalTableViewParentPanelDelegate <NSObject>

- (void)tableView:(HorizontalTableView *)tableView didSelectCellAtIndex:(NSInteger)index;
- (void)queueColumnView:(UIView *)vw;
- (UIView *)dequeueColumnView;

@end



@interface HorizontalTableView : UIView {
	NSMutableArray *_pageViews;
	UIScrollView *_scrollView;
	NSUInteger _currentPageIndex;
	NSUInteger _currentPhysicalPageIndex;
    
    NSInteger _visibleColumnCount;
    NSNumber *_columnWidth;
    
    id _delegate;
	id<HorizontalTableViewParentPanelDelegate> _panelDelegate;
	VideoRowController * tableController;
    
    NSMutableArray *_columnPool;
}

@property (nonatomic, assign) IBOutlet id<HorizontalTableViewDelegate> delegate;
@property (nonatomic, assign) id<HorizontalTableViewParentPanelDelegate> panelDelegate;
@property (nonatomic, retain) VideoRowController * tableController;

- (void)refreshData;
- (UIView *)dequeueColumnView;

@end
