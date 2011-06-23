//
//  NMChannelPanelView.m
//  ipad
//
//  Created by Bill So on 16/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMChannelPanelView.h"
#import <QuartzCore/QuartzCore.h>


@implementation NMChannelPanelView

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib {
	self.layer.shouldRasterize = YES;
	self.layer.shadowOffset = CGSizeZero;
	self.layer.shadowOpacity = 0.75f;
	self.layer.shadowRadius = 5.0f;
}

- (void)dealloc
{
    [super dealloc];
}

@end
