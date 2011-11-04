//
//  CategorySelectionViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategorySelectionGrid.h"

@protocol CategorySelectionViewControllerDelegate;

@interface CategorySelectionViewController : UIViewController {
    NSArray *categories;
    NSSet *subscribedChannels;
    
    NSMutableSet *subscribingChannels;
    NSMutableSet *unsubscribingChannels;
}

@property (nonatomic, retain) IBOutlet CategorySelectionGrid *categoryGrid;
@property (nonatomic, retain) IBOutlet UIView *progressView;
@property (nonatomic, retain) NSMutableIndexSet *selectedCategoryIndexes;
@property (nonatomic, assign) id<CategorySelectionViewControllerDelegate> delegate;

- (id)initWithCategories:(NSArray *)aCategories selectedCategoryIndexes:(NSMutableIndexSet *)aSelectedCategoryIndexes subscribedChannels:(NSSet *)subscribedChannels;

@end

@protocol CategorySelectionViewControllerDelegate <NSObject>
- (void)categorySelectionViewControllerWillDismiss:(CategorySelectionViewController *)controller;
@end