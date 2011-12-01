//
//  GridNavigationController.m
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridNavigationController.h"
#import "UIView+InteractiveAnimation.h"

@implementation GridNavigationController

@synthesize view;
@synthesize visibleGridController;

- (id)initWithRootGridController:(GridController *)gridController
{
    self = [super init];
    if (self) {
        view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        gridController.navigationController = self;
        gridController.view.frame = view.bounds;
        gridController.backButton.hidden = YES;
        gridController.currentChannel = nil;
        [view addSubview:gridController.view];
        
        _gridControllers = [[NSMutableArray alloc] initWithObjects:gridController, nil];
        visibleGridController = gridController;
    }
    return self;
}

- (void)dealloc
{
    [_gridControllers release];
    [view release];
    [visibleGridController release];
    
    [super dealloc];
}

- (NSArray *)gridControllers
{
    return _gridControllers;
}

#pragma mark - Navigation

- (void)pushGridController:(GridController *)gridController
{
    gridController.navigationController = self;
    gridController.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    [self.view addSubview:gridController.view];

    [UIView animateWithInteractiveDuration:0.5
                                animations:^{
                                    gridController.view.frame = self.view.bounds;
                                    visibleGridController.view.frame = CGRectOffset(self.view.bounds, -self.view.bounds.size.width, 0);
                                }
                                completion:^(BOOL finished){
                                    [visibleGridController.view removeFromSuperview];
                                    visibleGridController = gridController;
                                    [_gridControllers addObject:gridController];
                                }];    
}

- (void)popGridController
{
    if ([_gridControllers count] <= 1) {
        return;    
    }
    
    GridController *backGridController = [_gridControllers objectAtIndex:[_gridControllers count]-2];
    backGridController.view.frame = CGRectOffset(self.view.bounds, -self.view.bounds.size.width, 0);
    [self.view addSubview:backGridController.view];
    
    [UIView animateWithInteractiveDuration:0.5
                                animations:^{
                                    backGridController.view.frame = self.view.bounds;
                                    visibleGridController.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
                                }
                                completion:^(BOOL finished){
                                    [visibleGridController.view removeFromSuperview];
                                    [_gridControllers removeObjectAtIndex:[_gridControllers count]-1];
                                    visibleGridController = backGridController;
                                }];
}

@end
