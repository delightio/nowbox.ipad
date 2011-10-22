//
//  CategoryCellView.h
//  ipad
//
//  Created by Tim Chen on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryCellView : UIView {
    BOOL highlighted;
    BOOL selected;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, copy) NSString *categoryText;

@end
