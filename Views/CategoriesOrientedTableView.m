////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AGUITableView.m
//
//  Created by Andrew Gubanov on 5/23/11.
//  Copyright 2011 Andrew Gubanov. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Imports

#import "CategoriesOrientedTableView.h"
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Private Interface

@interface CategoriesOrientedTableView ()

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constants

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Implementation

@implementation CategoriesOrientedTableView

@synthesize orientedTableViewDataSource = _orientedTableViewDataSource;
@synthesize tableViewOrientation = _tableViewOrientation;

- (void)setOrientedTableViewDataSource:(id <UITableViewDataSource>)aDataSource
{
    _orientedTableViewDataSource = aDataSource;
    self.dataSource = self;
}

- (void)setTableViewOrientation:(AGTableViewOrientation)anOrientation
{
    if (_tableViewOrientation != anOrientation)
    {
        _tableViewOrientation = anOrientation;
        CGFloat angle = 0.0;
        if (_tableViewOrientation == kAGTableViewOrientationHorizontal)
        {
            angle = -M_PI/2.0;
            CGRect frame = self.frame;
            frame.origin = CGPointMake(abs(frame.size.width - frame.size.height) / 2.0, 
                                       (frame.size.height - frame.size.width) / -2.0);
            super.frame = frame;
        }
        self.transform = CGAffineTransformMakeRotation(angle);
        [self reloadData];
    }
}

- (void)setFrame:(CGRect)aFrame
{
    if (_tableViewOrientation == kAGTableViewOrientationHorizontal)
    {
        // FIXME: don't know why iOS 4 and 5 is rendering the transform differently
        if (NM_RUNNING_IOS_5) {
            aFrame.origin = CGPointMake(abs(aFrame.size.width - aFrame.size.height) / 2.0, 
                                       (aFrame.size.height - aFrame.size.width) / -2.0);
        } else {
            aFrame.origin = CGPointMake(230-abs(aFrame.size.width - aFrame.size.height) / 2.0, 
                                       230-(aFrame.size.height - aFrame.size.width) / -2.0);
        }
    }
    [super setFrame:aFrame];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    struct objc_method_description methodDescription = protocol_getMethodDescription(@protocol(UITableViewDataSource), 
        aSelector, NO, YES);
    
    BOOL result = [super respondsToSelector:aSelector];
    if (methodDescription.name != nil)
    {
        result = [self.orientedTableViewDataSource respondsToSelector:aSelector];
    }
    return result;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    struct objc_method_description methodDescription = protocol_getMethodDescription(@protocol(UITableViewDataSource), 
        [anInvocation selector], NO, YES);
    if (methodDescription.name != nil)
    {
        [anInvocation invokeWithTarget:self.orientedTableViewDataSource];
    }
    else
    {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.orientedTableViewDataSource tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.orientedTableViewDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    if (self.tableViewOrientation == kAGTableViewOrientationHorizontal)
    {
        cell.contentView.transform = CGAffineTransformMakeRotation(M_PI/2.0);
    }
    return cell;
}

@end
