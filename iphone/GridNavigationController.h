//
//  GridNavigationController.h
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GridController.h"

@interface GridNavigationController : NSObject {
    NSMutableArray *_gridControllers;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, readonly, retain) GridController *visibleGridController;
@property (nonatomic, readonly, retain) NSArray *gridControllers;

- (id)initWithRootGridController:(GridController *)gridController;
- (void)pushGridController:(GridController *)gridController;
- (void)popGridController;

@end
