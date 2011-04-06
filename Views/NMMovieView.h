//
//  NMMovieView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@interface NMMovieView : UIView {
	SEL action;
	id target;
	CGPoint initialCenter;
@private
	AVQueuePlayer * player_;
}

@property (nonatomic, retain) AVQueuePlayer * player;

- (void)addTarget:(id)atarget action:(SEL)anAction;

@end
