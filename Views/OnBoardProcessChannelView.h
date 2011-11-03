//
//  OnBoardProcessChannelView.h
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnBoardProcessChannelView : UIView

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIImageView *thumbnailImage;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *reasonLabel;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *reason;

@end
