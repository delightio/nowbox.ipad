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
}

@property (nonatomic, readonly) UILabel * textLabel;
@property (nonatomic, readonly) NMCachedImageView * imageView;

- (id)initWithHeight:(CGFloat)aHeight;

@end
