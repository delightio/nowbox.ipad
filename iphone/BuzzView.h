//
//  BuzzView.h
//  ipad
//
//  Created by Chris Haugli on 2/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BuzzViewDelegate;

@interface BuzzView : UIView {
    UIScrollView *scrollView;
    UIButton *touchArea;
    NSMutableArray *commentViews;
}

@property (nonatomic, retain) IBOutlet UIView *loadedCommentView;
@property (nonatomic, assign) IBOutlet id<BuzzViewDelegate> delegate;

- (void)addComment:(NSString *)comment fromUser:(NSString *)user withImage:(UIImage *)userImage atTime:(NSString *)timeText;
- (void)removeAllComments;

@end

@protocol BuzzViewDelegate <NSObject>
- (void)buzzViewDidTap:(BuzzView *)buzzView;
@end