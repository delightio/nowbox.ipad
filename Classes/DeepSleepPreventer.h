//
//  DeepSleepPreventer.h
//  ipad
//
//  Created by Chris Haugli on 12/13/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface DeepSleepPreventer : NSObject {
    AVAudioPlayer *audioPlayer;
}

+ (DeepSleepPreventer *)sharedInstance;
- (void)startPreventSleep;
- (void)stopPreventSleep;

@end