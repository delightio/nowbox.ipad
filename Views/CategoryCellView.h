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
    NSString *categoryTitle;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;

-(void)setCategoryText:(NSString *)newText;
@end
