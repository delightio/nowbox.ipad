//
//  NMTouchImageView.m
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTouchImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "NMStyleUtility.h"

#define NM_CHANNEL_THUMBNAIL_WIDTH		248.0f
#define NM_CHANNEL_THUMBNAIL_HEIGHT		174.0f


@implementation NMTouchImageView

@synthesize highlighted;
@dynamic channelName, image;

- (id)init {
	UIImage * img = [NMStyleUtility sharedStyleUtility].userPlaceholderImage;
	CGRect frame = CGRectMake(0.0, 0.0, img.size.width, img.size.height);
	self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
		
		// image view background
		self.layer.contents = (id)img.CGImage;
		
		// create highlight layer
		highlightLayer = [[CALayer layer] retain];
		highlightLayer.backgroundColor = [UIColor blackColor].CGColor;
		highlightLayer.opacity = 0.5f;
		highlightLayer.frame = CGRectMake(8.0, 11.0, NM_CHANNEL_THUMBNAIL_WIDTH, NM_CHANNEL_THUMBNAIL_HEIGHT);
		[self.layer addSublayer:highlightLayer];
		
		borderLayer = [CALayer layer];
		img = [UIImage imageNamed:@"channel_border"];
		borderLayer.contents = (id)img.CGImage;
		borderLayer.frame = self.layer.bounds;
		[self.layer addSublayer:borderLayer];
		
		img = [UIImage imageNamed:@"channel_title"];
		minChannelNameSize = img.size;
		img = [img stretchableImageWithLeftCapWidth:10 topCapHeight:0];
		channelNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		channelNameBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
		channelNameBtn.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		[channelNameBtn setBackgroundImage:img forState:UIControlStateNormal];
		channelNameBtn.bounds = CGRectMake(0.0, 0.0, minChannelNameSize.width, minChannelNameSize.height);
		[self addSubview:channelNameBtn];
		channelNameBtn.hidden = YES;
		channelNameBtn.userInteractionEnabled = NO;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	[highlightLayer release];
    [super dealloc];
}

- (void)addTarget:(id)aTarget action:(SEL)anAction {
	target = aTarget;
	action = anAction;
}

#pragma mark View attribute
- (void)setImage:(UIImage *)img {
	if ( img == nil && imageLayer ) {
		// remove the image layer
		[imageLayer removeFromSuperlayer];
		imageLayer = nil;
		return;
	} else if ( imageLayer ) {
		// remove the image layer, then continue
		[imageLayer removeFromSuperlayer];
	}
	imageLayer = [CALayer layer];
	imageLayer.contents = (id)img.CGImage;
	imageLayer.backgroundColor = [UIColor blackColor].CGColor;
	imageLayer.frame = CGRectMake(8.0, 11.0, NM_CHANNEL_THUMBNAIL_WIDTH, NM_CHANNEL_THUMBNAIL_HEIGHT);
	imageLayer.masksToBounds = YES;
	imageLayer.contentsGravity = kCAGravityResizeAspect;
	[self.layer insertSublayer:imageLayer below:borderLayer];
}

- (UIImage *)image {
	if ( imageLayer ) {
		return [UIImage imageWithCGImage:(CGImageRef)imageLayer.contents];
	}
	return nil;
}

- (NSString *)channelName {
	return [channelNameBtn titleForState:UIControlStateNormal];
}

- (void)setChannelName:(NSString *)chn {
	if ( chn == nil || [chn length] == 0 ) {
		channelNameBtn.hidden = YES;
		[channelNameBtn setTitle:@"" forState:UIControlStateNormal];
		return;
	}
	chn = [NSString stringWithFormat:@"   %@   ", chn];
	[channelNameBtn setTitle:chn forState:UIControlStateNormal];
	CGSize theSize = [chn sizeWithFont:channelNameBtn.titleLabel.font];
	if ( theSize.width > minChannelNameSize.width && theSize.width > NM_CHANNEL_THUMBNAIL_WIDTH - 10.0f) {
		// leave 5 px margin on left and right
		theSize.width = NM_CHANNEL_THUMBNAIL_WIDTH - 10.0;
	} else if ( theSize.width < minChannelNameSize.width ) {
		theSize.width = minChannelNameSize.width;
	}
	channelNameBtn.frame = CGRectMake(NM_CHANNEL_THUMBNAIL_WIDTH - theSize.width - 5.0f, 140.0, theSize.width, minChannelNameSize.height);
	channelNameBtn.hidden = NO;
}

#pragma mark Highlight 
- (void)highlightHandler:(id)sender {
	[self.layer addSublayer:highlightLayer];
	self.highlighted = YES;
}

- (void)clearHighlight:(id)sender {
	[highlightLayer removeFromSuperlayer];
	self.highlighted = NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self highlightHandler:nil];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	CGPoint thePoint = [atouch locationInView:self];
	if ( CGRectContainsPoint(self.bounds, thePoint) ) {
		if ( !self.highlighted ) {
			[self highlightHandler:nil];
		}
	} else if ( self.highlighted ) {
		// the touch is moved outside of the entry
		// remove highlight
		[self clearHighlight:nil];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	CGPoint thePoint = [atouch locationInView:self];
	if ( CGRectContainsPoint(self.bounds, thePoint) && target) {
		// fire the action
		[target performSelector:action withObject:self];
	}
	[self clearHighlight:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self clearHighlight:nil];
}


@end
