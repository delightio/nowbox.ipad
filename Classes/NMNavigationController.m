//
//  NMNavigationController.m
//  ipad
//
//  Created by Chris Haugli on 10/27/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMNavigationController.h"
#import "SearchChannelViewController.h"

// Avoids warning that super does not respond to selector
@interface UINavigationController (UINavigationBarDelegate)
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
@end

@implementation NMNavigationController

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    UIViewController *visibleController = self.visibleViewController;
    
    if ([visibleController isKindOfClass:[SearchChannelViewController class]]) {
        // Hide the keyboard before popping
        SearchChannelViewController *searchController = (SearchChannelViewController *)visibleController;
        
        if ([searchController.searchBar isFirstResponder]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
            [searchController.searchBar resignFirstResponder];
            return NO;
        }
    }
    
    if ([super respondsToSelector:@selector(navigationBar:shouldPopItem:)]) {
        return [super navigationBar:navigationBar shouldPopItem:item];
    }
    
    return YES;
}

- (void)keyboardDidHide:(NSNotification *)notification {
    // Now that the keyboard's gone, try popping again
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self popViewControllerAnimated:YES];
}

@end
