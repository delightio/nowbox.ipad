//
//  SizableNavigationController.m
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "SizableNavigationController.h"
#import "UIView+InteractiveAnimation.h"
#import "GridController.h"
#import "PhoneVideoPlaybackViewController.h"

@implementation SizableNavigationController

@synthesize view;
@synthesize visibleViewController;
@synthesize playbackModelController;
@synthesize playbackViewController;

- (id)initWithRootViewController:(UIViewController *)viewController
{
    self = [super init];
    
    if (self) {
        view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        viewController.view.frame = view.bounds;
        [view addSubview:viewController.view];
        
        if ([viewController isKindOfClass:[GridController class]]) {
            GridController *gridController = (GridController *)viewController;
            gridController.navigationController = self;
        }
        
        _viewControllers = [[NSMutableArray alloc] initWithObjects:viewController, nil];
        visibleViewController = viewController;        
    }
    
    return self;
}

- (void)dealloc
{
    [_viewControllers release];
    [view release];
    [visibleViewController release];
    
    [super dealloc];
}

- (NSArray *)viewControllers
{
    return _viewControllers;
}

#pragma mark - View lifecycle

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [visibleViewController willRotateToInterfaceOrientation:interfaceOrientation duration:duration];
}

#pragma mark - Navigation

- (void)pushViewController:(UIViewController *)viewController
{
    // Hide keyboard before pushing
    if ([visibleViewController isKindOfClass:[GridController class]]) {
        GridController *visibleGridController = (GridController *)visibleViewController;
        if ([visibleGridController.searchBar isFirstResponder]) {
            [visibleGridController.searchBar resignFirstResponder];
            [self performSelector:@selector(pushViewController:) withObject:viewController afterDelay:0.35];
            return;
        }
    }
    
    if ([viewController isKindOfClass:[GridController class]]) {
        GridController *gridController = (GridController *)viewController;
        gridController.navigationController = self;
    }
    
    viewController.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    [self.view addSubview:viewController.view];

    [viewController viewWillAppear:YES];
    [visibleViewController viewWillDisappear:YES];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         viewController.view.frame = self.view.bounds;
                         visibleViewController.view.frame = CGRectOffset(self.view.bounds, -self.view.bounds.size.width, 0);
                     }
                     completion:^(BOOL finished){
                         [visibleViewController.view removeFromSuperview];
                         [visibleViewController viewDidDisappear:YES];
                        
                         visibleViewController = viewController;
                         [_viewControllers addObject:viewController];
                         [viewController viewDidAppear:YES];
                     }];    
}

- (void)popViewController
{
    if ([_viewControllers count] <= 1) {
        return;    
    }
    
    // Hide keyboard before popping
    if ([visibleViewController isKindOfClass:[GridController class]]) {
        GridController *visibleGridController = (GridController *)visibleViewController;
        if ([visibleGridController.searchBar isFirstResponder]) {
            [visibleGridController.searchBar resignFirstResponder];
            [self performSelector:@selector(popViewController) withObject:nil afterDelay:0.35];
            return;
        }
    }
    
    UIViewController *backViewController = [_viewControllers objectAtIndex:[_viewControllers count]-2];
    backViewController.view.frame = CGRectOffset(self.view.bounds, -self.view.bounds.size.width, 0);
    [self.view addSubview:backViewController.view];
    
    [backViewController viewWillAppear:YES];
    [visibleViewController viewWillDisappear:YES];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         backViewController.view.frame = self.view.bounds;
                         visibleViewController.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
                     }
                     completion:^(BOOL finished){                                    
                         [visibleViewController.view removeFromSuperview];
                         [visibleViewController viewDidDisappear:YES];
                         [_viewControllers removeObjectAtIndex:[_viewControllers count]-1];
                                    
                         visibleViewController = backViewController;
                         [backViewController viewDidAppear:YES];
                     }];
}

@end
