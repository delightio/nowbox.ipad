//
//  ChannelContainerView.m
//  ipad
//
//  Created by Bill So on 25/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "ChannelContainerView.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>


@implementation ChannelContainerView
@synthesize textLabel;
@synthesize imageView;

//+ (Class)layerClass {
//	return [CAGradientLayer class];
//}

- (id)initWithHeight:(CGFloat)aHeight {
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, NM_CHANNEL_COLUMN_WIDTH, aHeight)];
	if ( self ) {
		NMStyleUtility * styleUtility = [NMStyleUtility sharedStyleUtility];
		self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		
		// background
//		CAGradientLayer * theLayer = (CAGradientLayer *)self.layer;
//		static NSMutableArray * colors = nil;
//		if (colors == nil) {
//			colors = [[NSMutableArray alloc] initWithCapacity:3];
//			UIColor *color = nil;
//			color = [UIColor colorWithRed:241.0f / 255.0f green:242.0f / 255.0f blue:246.0f / 255.0f alpha:1.0];
//			[colors addObject:(id)[color CGColor]];
//			color = [UIColor colorWithRed:214.0f / 255.0f green:214.0f / 255.0f blue:214.0f / 255.0f alpha:1.0];
//			[colors addObject:(id)[color CGColor]];
//		}
//		theLayer.shouldRasterize = YES;
//		[theLayer setColors:colors];
//		[theLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil]];
//		theLayer.startPoint = CGPointMake(0.0f, 0.277385657345732f);
//		theLayer.endPoint = CGPointMake(1.0f, 0.722614342654268f);
		
		// shadow
		CALayer * theLayer = self.layer;
//		theLayer.shouldRasterize = YES;
//		theLayer.shadowOffset = CGSizeZero;
//		theLayer.shadowOpacity = 0.8f;
//		theLayer.shadowRadius = 4.0f;
		
//		CALayer * theLayer = self.layer;
		theLayer.contents = (id)styleUtility.channelContainerBackgroundImage.CGImage;
		theLayer.contentsRect = CGRectMake(0.0, 0.1, 1.0, 0.8);
		
		// subviews
		textLabel = [[UILabel alloc] initWithFrame:CGRectMake(80.0f, 0.0f, NM_CHANNEL_COLUMN_WIDTH - 80.0f - 10.0f, aHeight)];
		textLabel.numberOfLines = 2;
		textLabel.font = styleUtility.channelNameFont;
		textLabel.textColor = styleUtility.channelPanelFontColor;
		textLabel.backgroundColor = styleUtility.clearColor;
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self addSubview:textLabel];
		
		CGFloat pos = floorf( (aHeight - 40.0f) / 2.0f );
		imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f, pos, 40.0f, 40.0f)];
		imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:imageView];
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
	[textLabel release];
	[imageView release];
    [super dealloc];
}

@end
