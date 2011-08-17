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
@synthesize removeSubscriptionButton;
@synthesize currentChannel;

//+ (Class)layerClass {
//	return [CAGradientLayer class];
//}

- (id)initWithHeight:(CGFloat)aHeight {
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, NM_CHANNEL_COLUMN_WIDTH, aHeight)];
	if ( self ) {
		NMStyleUtility * styleUtility = [NMStyleUtility sharedStyleUtility];
		self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		[self setClearsContextBeforeDrawing: NO];
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
//		CALayer * theLayer = self.layer;
//		theLayer.shouldRasterize = YES;
//		theLayer.shadowOffset = CGSizeZero;
//		theLayer.shadowOpacity = 0.8f;
//		theLayer.shadowRadius = 4.0f;
		
//		CALayer * theLayer = self.layer;
//		theLayer.contents = (id)styleUtility.channelContainerBackgroundImage.CGImage;
//		theLayer.contentsRect = CGRectMake(0.0, 0.1, 1.0, 0.8);
		
		// subviews
		textLabel = [[UILabel alloc] initWithFrame:CGRectMake(80.0f, 0.0f, NM_CHANNEL_COLUMN_WIDTH - 80.0f - 10.0f, aHeight)];
		textLabel.numberOfLines = 2;
		textLabel.font = styleUtility.channelNameFont;
		textLabel.textColor = styleUtility.channelPanelFontColor;
		textLabel.backgroundColor = styleUtility.clearColor;
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//		[self addSubview:textLabel];
		
		CGFloat pos = floorf( (aHeight - 40.0f) / 2.0f );

//        UIImageView *imageBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f-3, pos-3, 48.0f, 48.0f)];
//        imageBackgroundView.image = [UIImage imageNamed:@"channel-thumbnail-frame"];
//		[self addSubview:imageBackgroundView];
//        [imageBackgroundView release];
//        
//        UIImageView *bottomBorderView = [[UIImageView alloc] initWithFrame:CGRectMake(0, aHeight-1, 167.0f, 1.0f)];
//        bottomBorderView.opaque = YES;
//        bottomBorderView.image = [UIImage imageNamed:@"channel-bottom-border"];
//        bottomBorderView.clipsToBounds = YES;
//        bottomBorderView.contentMode = UIViewContentModeTopLeft;
//		[self addSubview:bottomBorderView];
//        [bottomBorderView release];
//        
//        UIImageView *topBorderView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 167.0f, 1.0f)];
//        topBorderView.opaque = YES;
//        topBorderView.image = [UIImage imageNamed:@"channel-bottom-border"];
//        topBorderView.clipsToBounds = YES;
//        topBorderView.contentMode = UIViewContentModeBottomLeft;
//		[self addSubview:topBorderView];
//        [topBorderView release];
        
		imageView = [[NMCachedImageView alloc] initWithFrame:CGRectMake(20.0f, pos, 40.0f, 40.0f)];
        imageView.opaque = YES;
		imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:imageView];
        
        removeSubscriptionButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        [removeSubscriptionButton setFrame:CGRectMake(130, 30, 25, 25)];
        [removeSubscriptionButton setTitle:@"X" forState:UIControlStateNormal];
        [removeSubscriptionButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [removeSubscriptionButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        removeSubscriptionButton.alpha = 0;
        [removeSubscriptionButton addTarget:self action:@selector(removeSubscription) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:removeSubscriptionButton];
        
        
        UISwipeGestureRecognizer *swipeGestureLeft = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedLeft:)] autorelease];
        swipeGestureLeft.numberOfTouchesRequired = 1;
        swipeGestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:swipeGestureLeft];
        
        UISwipeGestureRecognizer *swipeGestureRight = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedRight:)] autorelease];
        swipeGestureRight.numberOfTouchesRequired = 1;
        swipeGestureRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:swipeGestureRight];
        
	}
	return self;
}

- (void)swipedLeft:(id)sender {
    [UIView animateWithDuration:0.2
                          delay:0 
                        options:UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         removeSubscriptionButton.alpha = 1;
                     } 
                     completion:NULL];
}

- (void)swipedRight:(id)sender {
    [UIView animateWithDuration:0.2
                          delay:0 
                        options:UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         removeSubscriptionButton.alpha = 0;
                     } 
                     completion:NULL];
}

- (void)removeSubscription {
    if (currentChannel) {
        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:currentChannel];
        
        // TODO: temp only
        currentChannel.nm_subscribed = NO;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();

    [[NMStyleUtility sharedStyleUtility].channelContainerBackgroundImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height+2)];

    CGContextSetFillColorWithColor(context, textLabel.textColor.CGColor);
    CGSize theStringSize = [textLabel.text  sizeWithFont:textLabel.font constrainedToSize:textLabel.frame.size lineBreakMode:textLabel.lineBreakMode];
    [textLabel.text drawInRect:CGRectMake(80, (self.frame.size.height-theStringSize.height)/2, NM_CHANNEL_COLUMN_WIDTH - 80.0f - 10.0f, theStringSize.height) withFont:textLabel.font lineBreakMode:textLabel.lineBreakMode alignment:textLabel.textAlignment];

    CGFloat pos = floorf( (self.frame.size.height - 40.0f) / 2.0f );
    
    [[UIImage imageNamed:@"channel-thumbnail-frame"] drawInRect:CGRectMake(20.0f-3, pos-3, 48.0f, 48.0f)];
    
    [[UIImage imageNamed:@"channel-bottom-border"] drawInRect:CGRectMake(0, self.frame.size.height-1, 167.0f, 2.0f)];
    
    [[UIImage imageNamed:@"channel-bottom-border"] drawInRect:CGRectMake(0, -1, 167.0f, 2.0f)];
    
}

 
- (void)dealloc
{
    [removeSubscriptionButton release];
	[textLabel release];
	[imageView release];
    [super dealloc];
}

@end
