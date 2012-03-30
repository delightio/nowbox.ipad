//
//  NMChannel20MigrationPolicy.m
//  ipad
//
//  Created by Bill So on 3/31/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMChannel20MigrationPolicy.h"

@implementation NMChannel20MigrationPolicy

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
	return [super createRelationshipsForDestinationInstance:dInstance entityMapping:mapping manager:manager error:error];
}

@end
