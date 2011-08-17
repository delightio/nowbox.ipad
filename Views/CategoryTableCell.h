//
//  CategoryTableCell.h
//  ipad
//
//  Created by Tim Chen on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CategoryCellView;

@interface CategoryTableCell : UITableViewCell {
    CategoryCellView *categoryView;
}

@property (nonatomic, retain) CategoryCellView *categoryView;

-(void)setCategoryTitle:(NSString *)newTitle;
-(void)redisplay;

@end
