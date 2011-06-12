//
//  NMAVPlayerItem.h
//  ipad
//
//  Created by Bill So on 11/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@class NMVideo;

@interface NMAVPlayerItem : AVPlayerItem {
    NMVideo * nmVideo;
}

@property (nonatomic, assign) NMVideo * nmVideo;

@end
