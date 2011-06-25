//
//  ChannelTableCellView.m
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChannelTableCellView.h"
#import "NMChannel.h"
#import "NMTouchImageView.h"
#import "NMCacheController.h"
#import <QuartzCore/QuartzCore.h>


#define NM_CHANNEL_CELL_MARGIN		44.0f
#define NM_CHANNEL_CELL_LEFT_PADDING	76.0f

@interface ChannelNameBackgroundView : UIView {    
}

@end

@implementation ChannelNameBackgroundView

+ (Class)layerClass {
	return [CAGradientLayer class];
}

- (id)init {
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, NM_CHANNEL_COLUMN_WIDTH, NM_VIDEO_CELL_HEIGHT)];
	if ( self ) {
		
	}
	return self;
}

- (void)displayLayer:(CALayer *)layer {
	CAGradientLayer * theLayer = (CAGradientLayer *)layer;
	static NSMutableArray * colors = nil;
	if (colors == nil) {
		colors = [[NSMutableArray alloc] initWithCapacity:3];
		UIColor *color = nil;
		color = [UIColor colorWithRed:241.0f / 255.0f green:242.0f / 255.0f blue:246.0f / 255.0f alpha:1.0];
		[colors addObject:(id)[color CGColor]];
		color = [UIColor colorWithRed:214.0f / 255.0f green:214.0f / 255.0f blue:214.0f / 255.0f alpha:1.0];
		[colors addObject:(id)[color CGColor]];
	}
	[theLayer setColors:colors];
	[theLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil]];
}

@end

@implementation ChannelTableCellView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
		channelBackgroundView = [[ChannelNameBackgroundView alloc] init];
		channelBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		[self insertSubview:channelBackgroundView aboveSubview:self.contentView];
    }
    return self;
}


//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    
//    [super setSelected:selected animated:animated];
//    
//    // Configure the view for the selected state.
//}


- (void)dealloc {
	[channelBackgroundView release];
    [super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
}

@end
