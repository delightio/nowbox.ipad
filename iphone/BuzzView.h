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
    NSMutableArray *commentScrollViews;
    NSMutableArray *commentViews;
    NSMutableArray *actionButtonViews;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIScrollView *mentionsScrollView;
@property (nonatomic, retain) IBOutlet UIButton *touchArea;
@property (nonatomic, retain) IBOutlet UIView *noCommentsView;
@property (nonatomic, retain) IBOutlet UILabel *noCommentsLabel;
@property (nonatomic, assign) BOOL showsActionButtons;
@property (nonatomic, assign) IBOutlet id<BuzzViewDelegate> delegate;

- (void)addMention;
- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username;
- (void)removeAllMentions;
- (IBAction)touchAreaPressed:(id)sender;
- (IBAction)likeButtonPressed:(id)sender;
- (IBAction)commentButtonPressed:(id)sender;

@end

@protocol BuzzViewDelegate <NSObject>
@optional
- (void)buzzViewDidTap:(BuzzView *)buzzView;
- (void)buzzView:(BuzzView *)buzzView didPressLikeButton:(id)sender;
- (void)buzzView:(BuzzView *)buzzView didPressCommentButton:(id)sender;
@end