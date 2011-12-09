//
//  TestGridController.m
//  ipad
//
//  Created by Chris Haugli on 12/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "TestGridController.h"
#import "GridItemView.h"

@implementation TestGridController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        numberOfItems = 4;
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = @"Test";
}

#pragma mark - Actions

- (void)addItems
{
    if (stop || numberOfItems >= 20) return;
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(addItems) userInfo:nil repeats:NO];
    NSLog(@"inserting item at index %i", numberOfItems);
    [self.gridView insertItemAtIndex:numberOfItems++];
}

- (void)removeItems
{
    if (stop || numberOfItems <= 3) return;
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(removeItems) userInfo:nil repeats:NO];
    [self.gridView deleteItemAtIndex:--numberOfItems];
    NSLog(@"deleting item at index %i", numberOfItems);    
}

- (IBAction)itemPressed:(id)sender
{
    NSUInteger index = [sender index];
    
    if (index % 3 == 0) {
        [self addItems];
    } else if (index % 3 == 1) {
        [self removeItems];
    } else if (index % 3 == 2) {
        if (!updating) {
            updating = YES;
            stop = NO;
            [self.gridView beginUpdates];
            NSLog(@"begin updates");
        } else {
            stop = YES;
            updating = NO;
            [self.gridView endUpdates];
            NSLog(@"end updates");
        }
    }
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return numberOfItems;
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    GridItemView *itemView = (GridItemView *)[gridScrollView dequeueReusableSubview];
    if (!itemView) {
        itemView = [[[GridItemView alloc] initWithFrame:CGRectMake(0, 0, gridScrollView.itemSize.width, gridScrollView.itemSize.height)] autorelease];
        itemView.titleLabel.font = [UIFont boldSystemFontOfSize:36];
        [itemView addTarget:self action:@selector(itemPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    itemView.index = index;
    itemView.highlighted = NO;
    
    if (index % 3 == 0) {
        itemView.titleLabel.text = [NSString stringWithFormat:@"%i +", index];
    } else if (index % 3 == 1) {
        itemView.titleLabel.text = [NSString stringWithFormat:@"%i -", index];
    } else if (index % 3 == 2) {
        itemView.titleLabel.text = [NSString stringWithFormat:@"%i S", index];
    }
    
    return itemView;
}

@end
