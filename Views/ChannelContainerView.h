//
//  ChannelContainerView.h
//  ipad
//
//  Created by Bill So on 25/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ChannelContainerView : UIView {
    UILabel * textLabel;
	UIImageView * imageView;
}

@property (nonatomic, readonly) UILabel * textLabel;
@property (nonatomic, readonly) UIImageView * imageView;

- (id)initWithHeight:(CGFloat)aHeight;

@end
