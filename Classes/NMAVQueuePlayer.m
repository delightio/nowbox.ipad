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
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"re-insert original item back to the queue player");
#endif
			[self insertItem:cItem afterItem:self.currentItem];
		} else {
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"CANNOT insert back");
#endif
		}
	}
}

@end
