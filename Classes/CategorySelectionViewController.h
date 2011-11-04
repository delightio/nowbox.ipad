//
//  CategorySelectionViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategorySelectionGrid.h"

@interface CategorySelectionViewController : UIViewController {
    NSArray *categories;
}

@property (nonatomic, retain) CategorySelectionGrid *categoryGrid;

- (id)initWithCategories:(NSArray *)aCategories;

@end
