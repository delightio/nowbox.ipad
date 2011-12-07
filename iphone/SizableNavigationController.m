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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisappear:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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


#pragma mark - Notifications

- (void)resizeViewForKeyboardUserInfo:(NSDictionary *)userInfo
{
    NSValue *sizeValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSValue *durationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    CGSize keyboardSize = [sizeValue CGRectValue].size;
    
    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];
    
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame.size.height = self.view.superview.frame.size.height - keyboardSize.height;
    } else {
        frame.size.height = self.view.superview.frame.size.width - keyboardSize.width;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.frame = frame;                         
                     }];    
}

- (void)keyboardWillAppear:(NSNotification *)notification
{
    [self resizeViewForKeyboardUserInfo:[notification userInfo]];
}

- (void)keyboardWillDisappear:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSValue *durationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];

    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];
    
    CGRect frame = self.view.frame;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame.origin.y = self.view.superview.frame.size.height / 2;
        frame.size.height = self.view.superview.frame.size.height / 2;
    } else {
        frame.origin.y = 0;
        frame.size.height = self.view.superview.frame.size.width;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.frame = frame;
                     }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    [self resizeViewForKeyboardUserInfo:[notification userInfo]];
}

@end
