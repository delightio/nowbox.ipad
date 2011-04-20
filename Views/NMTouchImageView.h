//
//  NMTouchImageView.h
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NMTouchImageView : UIView {
	CALayer * highlightLayer;
	CALayer * borderLayer;
	CALayer * imageLayer;
	SEL action;
	id target;
	
	UIButton * channelNameBtn;
	CGSize minChannelNameSize;
	BOOL highlighted;
}

@property (nonatomic) BOOL highlighted;
@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSString * channelName;

- (void)addTarget:(id)aTarget action:(SEL)anAction;

@end
