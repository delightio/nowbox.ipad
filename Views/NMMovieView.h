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
	UIActivityIndicatorView * activityIndicator;
	UILabel * statusLabel;
@private
	AVQueuePlayer * player_;
}

@property (nonatomic, retain) AVQueuePlayer * player;
@property (nonatomic, readonly) UILabel * statusLabel;
@property (nonatomic, readonly) UIActivityIndicatorView * activityIndicator;

- (void)addTarget:(id)atarget action:(SEL)anAction;

@end
