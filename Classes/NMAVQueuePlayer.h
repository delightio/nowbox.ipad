//
//  NMAVQueuePlayer.h
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


/*!
 It maintains, in all time, at most 3 pending queue item
 */

@interface NMAVQueuePlayer : AVQueuePlayer {
    
}

- (void)revertPreviousItem:(AVPlayerItem *)item;

@end
