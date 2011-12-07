//
//  GridItemView.m
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridItemView.h"
#import <QuartzCore/QuartzCore.h>

@implementation GridItemView

@synthesize contentView;
@synthesize thumbnail;
@synthesize titleLabel;
@synthesize index;
@synthesize playing;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"GridItemView" owner:self options:nil];
        
        contentView.frame = self.bounds;
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5;
    }
    return self;
}

- (void)dealloc
{
    [contentView release];
    [thumbnail release];
    [titleLabel release];
    
    [super dealloc];
}

- (void)updateBackgroundColor
{
    if (self.highlighted) {
        contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    } else if (playing) {
        contentView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.3 alpha:0.7];
    } else {
        contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self updateBackgroundColor];
}

- (void)unhighlight
{
    [self setHighlighted:NO];
}

- (void)setPlaying:(BOOL)aPlaying
{
    playing = aPlaying;
    [self updateBackgroundColor];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self setHighlighted:YES];
    touching = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    if (touching) {
        UITouch *touch = [touches anyObject];
        [self setHighlighted:CGRectContainsPoint(self.bounds, [touch locationInView:self])];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (CGRectContainsPoint(self.bounds, [touch locationInView:self])) {
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(unhighlight) userInfo:nil repeats:NO];
    }
    touching = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self setHighlighted:NO];
    touching = NO;
}

@end