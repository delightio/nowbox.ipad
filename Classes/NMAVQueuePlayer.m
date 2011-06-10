//
//  NMAVQueuePlayer.m
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMAVQueuePlayer.h"


@implementation NMAVQueuePlayer

- (void)revertPreviousItem:(AVPlayerItem *)anItem {
	// move back to the previous item
	AVPlayerItem * cItem = [self.currentItem retain];
	if ( [self canInsertItem:anItem afterItem:cItem] ) {
		[self insertItem:anItem afterItem:cItem];
		[self advanceToNextItem];
		if ( [self canInsertItem:cItem afterItem:self.currentItem] ) {
			NSLog(@"inserting original item back to the queue player");
			[self insertItem:cItem afterItem:self.currentItem];
		} else {
			NSLog(@"CANNOT insert back");
		}
	}
}

@end
