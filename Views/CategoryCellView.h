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
    NSString *categoryTitle;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

-(void)setCategoryText:(NSString *)newText;
@end
