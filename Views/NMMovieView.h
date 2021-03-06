//
//  NMMovieView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>


@class NMAVQueuePlayer;

@interface NMMovieView : UIView {
//	SEL action;
//	id target;
	CGPoint initialCenter;
	UIActivityIndicatorView * activityIndicator;
	UILabel * statusLabel;
	UIImageView * logoView;
@private
	NMAVQueuePlayer * player_;
	UIView * airPlayIndicatorView;
}

@property (nonatomic, retain) NMAVQueuePlayer * player;
@property (nonatomic, readonly) UILabel * statusLabel;
@property (nonatomic, readonly) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) IBOutlet UIView * airPlayIndicatorView;

//- (void)addTarget:(id)atarget action:(SEL)anAction;
- (void)setActivityIndicationHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)hideAirPlayIndicatorView:(BOOL)hidden;

@end
