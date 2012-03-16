//
//  TwitterGridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/29/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridDataSource.h"

@interface TwitterGridDataSource : GridDataSource

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end
