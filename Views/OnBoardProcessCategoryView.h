//
//  OnBoardProcessCategoryView.h
//  ipad
//
//  Created by Chris Haugli on 11/10/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnBoardProcessCategoryView : UIView

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIButton *button;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, copy) NSString *title;

@end
