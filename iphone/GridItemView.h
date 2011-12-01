//
//  GridItemView.h
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"

@interface GridItemView : UIControl {
    BOOL touching;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *thumbnail;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) NSUInteger index;

@end
