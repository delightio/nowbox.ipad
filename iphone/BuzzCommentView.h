//
//  BuzzCommentView.h
//  ipad
//
//  Created by Chris Haugli on 2/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"

@interface BuzzCommentView : UIView {
    CGFloat commentRightPadding;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *userImageView;
@property (nonatomic, retain) IBOutlet UILabel *userLabel;
@property (nonatomic, retain) IBOutlet UIImageView *serviceIcon;
@property (nonatomic, retain) IBOutlet UILabel *timeLabel;
@property (nonatomic, retain) IBOutlet UILabel *commentLabel;
@property (nonatomic, retain) IBOutlet UILabel *likesCountLabel;
@property (nonatomic, assign) BOOL showsLikesCount;

@end
