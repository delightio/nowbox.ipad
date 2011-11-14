//
//  CategorySelectionGrid.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategorySelectionGrid.h"
#import "OnBoardProcessCategoryView.h"

@implementation CategorySelectionGrid

@synthesize categoryTitles;
@synthesize numberOfColumns;
@synthesize horizontalSpacing;
@synthesize verticalSpacing;
@synthesize itemHeight;
@synthesize selectedViewIndexes;
@synthesize gridDelegate;

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    categoryViews = [[NSMutableArray alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
    selectedViewIndexes = [[NSMutableIndexSet alloc] init];
    numberOfColumns = 3;
    horizontalSpacing = 30.0f;
    verticalSpacing = 10.0f;
    itemHeight = 91.0f;
    
    [self reloadData];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [categoryTitles release];
    [categoryViews release];
    [recycledViews release];
    [selectedViewIndexes release];
    
    [super dealloc];
}

- (void)reloadData
{
    // Remove old views
    for (UIView *view in categoryViews) {
        [view removeFromSuperview];
        [recycledViews addObject:view];
    }
    [categoryViews removeAllObjects];
    
    // Add new views
    NSUInteger row = 0, col = 0;    
    CGFloat itemWidth = round((self.frame.size.width - (numberOfColumns - 1) * horizontalSpacing) / numberOfColumns);
    
    for (NSString *title in categoryTitles) {
        OnBoardProcessCategoryView *categoryView = [[[recycledViews anyObject] retain] autorelease];
        if (categoryView) {
            [recycledViews removeObject:categoryView];
        } else {
            categoryView = [[[OnBoardProcessCategoryView alloc] init] autorelease];
        }
        
        categoryView.frame = CGRectMake(col * (itemWidth + horizontalSpacing), row * (itemHeight + verticalSpacing),
                                          itemWidth, itemHeight);
        [categoryView setTitle:title];
        [categoryView.button setTag:row*numberOfColumns + col];        
        [categoryView.button addTarget:self action:@selector(categoryViewPressed:) forControlEvents:UIControlEventTouchUpInside];
        [categoryView.button setSelected:[selectedViewIndexes containsIndex:categoryView.tag]];
        [self addSubview:categoryView];
        [categoryViews addObject:categoryView];
        
        self.contentSize = CGSizeMake(self.frame.size.width, categoryView.frame.origin.y + categoryView.frame.size.height + verticalSpacing);

        col++;
        if (col >= numberOfColumns) {
            row++;            
            col = 0;
        }
    }
}

- (void)categoryViewPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSInteger categoryIndex = button.tag;
    
    if ([selectedViewIndexes containsIndex:categoryIndex]) {
        [button setSelected:NO];
        [selectedViewIndexes removeIndex:categoryIndex];
    } else {
        [button setSelected:YES];
        [selectedViewIndexes addIndex:categoryIndex];
    }
    
    [gridDelegate categorySelectionGrid:self didSelectCategoryAtIndex:categoryIndex];
}

- (void)setCategoryTitles:(NSArray *)aCategoryTitles
{
    if (categoryTitles != aCategoryTitles) {
        [categoryTitles release];
        categoryTitles = [aCategoryTitles retain];
    }
    
    [self reloadData];
}

- (void)setNumberOfColumns:(NSUInteger)aNumberOfColumns
{
    numberOfColumns = aNumberOfColumns;
    [self reloadData];
}

- (void)setHorizontalSpacing:(CGFloat)aHorizontalSpacing
{
    horizontalSpacing = aHorizontalSpacing;
    [self reloadData];
}

- (void)setVerticalSpacing:(CGFloat)aVerticalSpacing
{
    verticalSpacing = aVerticalSpacing;
    [self reloadData];
}

- (void)setSelectedViewIndexes:(NSMutableIndexSet *)aSelectedViewIndexes
{
    [selectedViewIndexes release];
    selectedViewIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:aSelectedViewIndexes];

    [self reloadData];    
}

@end
