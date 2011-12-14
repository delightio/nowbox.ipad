//
//  DeepSleepPreventer.m
//  ipad
//
//  Created by Chris Haugli on 12/13/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "DeepSleepPreventer.h"

@implementation DeepSleepPreventer

static DeepSleepPreventer *sharedInstance = nil;

+ (DeepSleepPreventer *)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [[DeepSleepPreventer alloc] init];
    }
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Set up audio session
        AudioSessionInitialize(NULL, NULL, NULL, NULL);
        AudioSessionSetActive(true);
        
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
		
        // Set up audio player
		NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"silent" ofType:@"wav"];
		audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundFilePath] error:nil];
        audioPlayer.numberOfLoops = -1; // Repeat forever
        audioPlayer.currentTime = 0;
		[audioPlayer prepareToPlay];        
	}
    return self;
}

- (void)dealloc
{
	[audioPlayer release];
    
	[super dealloc];
}

- (void)startPreventSleep
{
    [audioPlayer play];
}

- (void)stopPreventSleep
{
    [audioPlayer stop];
}

@end