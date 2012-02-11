//
//  YouTubeGridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridDataSource.h"

@interface YouTubeGridDataSource : GridDataSource

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end
