//
//  CategorySelectionGrid.h
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CategorySelectionGridDelegate;

@interface CategorySelectionGrid : UIView {
    NSMutableArray *categoryViews;
    NSMutableSet *recycledViews;
}

@property (nonatomic, retain) NSArray *categoryTitles;
@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) CGFloat horizontalSpacing;
@property (nonatomic, assign) CGFloat verticalSpacing;
@property (nonatomic, retain) NSMutableIndexSet *selectedViewIndexes;
@property (nonatomic, assign) id<CategorySelectionGridDelegate> delegate;

@end

@protocol CategorySelectionGridDelegate <NSObject>
- (void)categorySelectionGrid:(CategorySelectionGrid *)categoryGrid didSelectCategoryAtIndex:(NSUInteger)index;
@end