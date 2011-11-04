//
//  CategorySelectionGrid.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategorySelectionGrid.h"

@implementation CategorySelectionGrid

@synthesize categoryTitles;
@synthesize numberOfColumns;
@synthesize horizontalSpacing;
@synthesize verticalSpacing;
@synthesize selectedButtonIndexes;
@synthesize delegate;

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    categoryButtons = [[NSMutableArray alloc] init];
    selectedButtonIndexes = [[NSMutableIndexSet alloc] init];
    numberOfColumns = 2;
    horizontalSpacing = 10.0f;
    verticalSpacing = 10.0f;
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
    [categoryButtons release];
    [selectedButtonIndexes release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    // Remove old buttons
    for (UIButton *button in categoryButtons) {
        [button removeFromSuperview];
    }
    
    // Add new buttons
    NSUInteger row = 0, col = 0;
    NSUInteger numberOfRows = ceil((float)[categoryTitles count] / (numberOfColumns > 0 ? numberOfColumns : 1));
    
    CGFloat itemWidth = (self.frame.size.width - (numberOfColumns - 1) * horizontalSpacing) / numberOfColumns;
    CGFloat itemHeight = (self.frame.size.height - (numberOfRows - 1) * verticalSpacing) / numberOfRows;
    
    for (NSString *title in categoryTitles) {
        UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        categoryButton.frame = CGRectMake(col * (itemWidth + horizontalSpacing), row * (itemHeight + verticalSpacing),
                                          itemWidth, itemHeight);
        [categoryButton setTitle:title forState:UIControlStateNormal];
        [categoryButton setTag:row*numberOfColumns + col];        
        [categoryButton addTarget:self action:@selector(categoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([selectedButtonIndexes containsIndex:categoryButton.tag]) {
            [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-red-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];    
            [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
            [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }

        [self addSubview:categoryButton];
        [categoryButtons addObject:categoryButton];
        
        col++;
        if (col >= numberOfColumns) {
            row++;            
            col = 0;
        }
    }
}

- (void)categoryButtonPressed:(id)sender
{
    UIButton *categoryButton = (UIButton *)sender;
    NSInteger categoryIndex = [categoryButton tag];
    if ([selectedButtonIndexes containsIndex:categoryIndex]) {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];        
        [selectedButtonIndexes removeIndex:categoryIndex];
    } else {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-red-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [selectedButtonIndexes addIndex:categoryIndex];
    }
    
    [delegate categorySelectionGrid:self didSelectCategoryAtIndex:categoryIndex];
}

- (void)setCategoryTitles:(NSArray *)aCategoryTitles
{
    if (categoryTitles != aCategoryTitles) {
        [categoryTitles release];
        categoryTitles = [aCategoryTitles retain];
    }
    
    [self setNeedsLayout];
}

- (void)setNumberOfColumns:(NSUInteger)aNumberOfColumns
{
    numberOfColumns = aNumberOfColumns;
    [self setNeedsLayout];
}

- (void)setHorizontalSpacing:(CGFloat)aHorizontalSpacing
{
    horizontalSpacing = aHorizontalSpacing;
    [self setNeedsLayout];
}

- (void)setVerticalSpacing:(CGFloat)aVerticalSpacing
{
    verticalSpacing = aVerticalSpacing;
    [self setNeedsLayout];
}

- (void)setSelectedButtonIndexes:(NSMutableIndexSet *)aSelectedButtonIndexes
{
    [selectedButtonIndexes release];
    selectedButtonIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:aSelectedButtonIndexes];

    [self setNeedsLayout];    
}

@end
