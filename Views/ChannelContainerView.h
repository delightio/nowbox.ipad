//
//  ChannelContainerView.h
//  ipad
//
//  Created by Bill So on 25/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"


@interface ChannelContainerView : UIView {
    UILabel * textLabel;
	NMCachedImageView * imageView;
    UIButton * removeSubscriptionButton;
    NMChannel *currentChannel;
}

@property (nonatomic, readonly) UILabel * textLabel;
@property (nonatomic, readonly) NMCachedImageView * imageView;
@property (nonatomic, retain) UIButton * removeSubscriptionButton;
@property (nonatomic, retain) NMChannel *currentChannel;

- (id)initWithHeight:(CGFloat)aHeight;
- (void)swipedLeft:(id)sender;
- (void)swipedRight:(id)sender;
- (void)removeSubscription;

@end
