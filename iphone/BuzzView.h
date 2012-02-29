//
//  BuzzView.h
//  ipad
//
//  Created by Chris Haugli on 2/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuzzCommentView.h"

@protocol BuzzViewDelegate;

@interface BuzzView : UIView {
    NSMutableArray *commentViews;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIButton *touchArea;
@property (nonatomic, retain) IBOutlet UIView *noCommentsView;
@property (nonatomic, retain) IBOutlet UILabel *noCommentsLabel;
@property (nonatomic, retain) IBOutlet UIView *actionButtonsView;
@property (nonatomic, assign) BOOL showsActionButtons;
@property (nonatomic, assign) IBOutlet id<BuzzViewDelegate> delegate;

- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username;
- (void)removeAllComments;
- (IBAction)touchAreaPressed:(id)sender;

@end

@protocol BuzzViewDelegate <NSObject>
- (void)buzzViewDidTap:(BuzzView *)buzzView;
@end