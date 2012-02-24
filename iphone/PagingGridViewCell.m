//
//  PagingGridViewCell.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PagingGridViewCell.h"
#import <QuartzCore/QuartzCore.h>

#define kPressAndHoldDuration 0.8f
#define kDraggingScaleFactor 1.1
#define kEditingScaleFactor 0.85

@implementation PagingGridViewCell

@synthesize contentView;
@synthesize image;
@synthesize label;
@synthesize activityIndicator;
@synthesize deleteButton;
@synthesize highlightView;
@synthesize index;
@synthesize columnSpan;
@synthesize rowSpan;
@synthesize editing;
@synthesize dragging;
@synthesize lastDragLocation;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Load the view from a nib
        [[NSBundle mainBundle] loadNibNamed:@"PagingGridViewCell" owner:self options:nil];
        
        if (CGRectEqualToRect(frame, CGRectZero)) {
            self.frame = contentView.bounds;
        }

        contentView.frame = self.bounds;        
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        
        deleteButton.center = CGPointMake(12, 12);
        deleteButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:deleteButton];
        
        // Set the font depending on if it's available (iOS 4 doesn't have Futura Condensed Medium)
        UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:label.font.pointSize];
        if (!font) {
            font = [UIFont fontWithName:@"Futura-Medium" size:18];
        }
        [label setFont:font];
        
        self.clipsToBounds = NO;
        
        [self addTarget:self action:@selector(handleTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(handleTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(handleCancelTouch:) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchDragOutside];
        [self addTarget:self action:@selector(handleDrag:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    }
    return self;
} 

- (void)dealloc
{
    [pressAndHoldTimer invalidate];
    
    [contentView release];
    [image release];
    [label release];
    [activityIndicator release];
    [deleteButton release];
    [highlightView release];
    
    [super dealloc];
}

- (void)cancelPressAndHoldTimer
{
    [pressAndHoldTimer invalidate];
    pressAndHoldTimer = nil;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];    
    highlightView.hidden = !highlighted;
}

- (void)didMoveToSuperview
{
    [self setHighlighted:NO];
}

- (void)setEditing:(BOOL)isEditing
{
    editing = isEditing;
    
    if (editing) {
        contentView.transform = CGAffineTransformMakeScale(kEditingScaleFactor, kEditingScaleFactor);
    } else {
        contentView.transform = CGAffineTransformIdentity;
    }
    
    if (editing && [delegate respondsToSelector:@selector(gridViewCellShouldShowDeleteButton:)] && [delegate gridViewCellShouldShowDeleteButton:self]) {
        deleteButton.alpha = 1;
    } else {
        deleteButton.alpha = 0;
    }
}

- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.editing = isEditing;
                         }];
    } else {
        self.editing = isEditing;
    }
}

- (void)setDragging:(BOOL)isDragging
{
    dragging = isDragging;
    
    [self.superview bringSubviewToFront:self];

    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         if (dragging) {
                             self.alpha = 0.7;
                             contentView.transform = CGAffineTransformMakeScale(kDraggingScaleFactor, kDraggingScaleFactor);
                             deleteButton.transform = CGAffineTransformMake(kDraggingScaleFactor, 0, 0, kDraggingScaleFactor, -17, -15);
                         } else {
                             self.alpha = 1.0;
                             deleteButton.transform = CGAffineTransformIdentity;
                             if (editing) {
                                 contentView.transform = CGAffineTransformMakeScale(kEditingScaleFactor, kEditingScaleFactor);
                             } else {
                                 contentView.transform = CGAffineTransformIdentity;
                             }
                         }
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - IBActions

- (IBAction)deleteButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(gridViewCellDidPressDeleteButton:)]) {
        [delegate gridViewCellDidPressDeleteButton:self];
    }
}

#pragma mark - Touches

- (void)didPressAndHold
{
    pressAndHoldTimer = nil;
    if (dragging) return;
    
    if ([delegate respondsToSelector:@selector(gridViewCellDidPressAndHold:)]) {
        [delegate gridViewCellDidPressAndHold:self];
    }
    
    BOOL shouldDrag = YES;
    if ([delegate respondsToSelector:@selector(gridViewCellShouldStartDragging:)]) {
        shouldDrag = [delegate gridViewCellShouldStartDragging:self];
    }
    
    if (shouldDrag) {
        if ([delegate respondsToSelector:@selector(gridViewCellDidStartDragging:)]) {
            [delegate gridViewCellDidStartDragging:self];
        }
        
        [self setDragging:YES];
    }
}

- (void)didStopDragging
{
    [self setDragging:NO];

    if ([delegate respondsToSelector:@selector(gridViewCellDidEndDragging:)]) {
        [delegate gridViewCellDidEndDragging:self];
    }
}

- (void)handleTouchUp:(id)sender
{
    if (dragging) {
        [self didStopDragging];
    } else if (pressAndHoldTimer) {
        [self cancelPressAndHoldTimer];        
        [delegate gridViewCellDidTap:self];
    }
}

- (void)handleTouchDown:(id)sender withEvent:(UIEvent *)event
{
    [self cancelPressAndHoldTimer];
    pressAndHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kPressAndHoldDuration
                                                         target:self
                                                       selector:@selector(didPressAndHold)
                                                       userInfo:nil
                                                        repeats:NO];
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint dragStartLocation = [touch locationInView:self.superview];
    dragAnchorPoint = CGPointMake(dragStartLocation.x - self.center.x, dragStartLocation.y - self.center.y);
}

- (void)handleCancelTouch:(id)sender
{    
    [self cancelPressAndHoldTimer];
    if (dragging) {
        [self didStopDragging];
    } else {
        [self cancelPressAndHoldTimer];
    }
}

- (void)handleDrag:(id)sender withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];

    if (editing && !dragging) {
        BOOL shouldDrag = YES;
        if ([delegate respondsToSelector:@selector(gridViewCellShouldStartDragging:)]) {
            shouldDrag = [delegate gridViewCellShouldStartDragging:self];
        }
        
        if (shouldDrag) {
            CGPoint dragStartLocation = [touch locationInView:self.superview];
            dragAnchorPoint = CGPointMake(dragStartLocation.x - self.center.x, dragStartLocation.y - self.center.y);
            [self setDragging:YES];
            
            [pressAndHoldTimer invalidate];
            pressAndHoldTimer = nil;
            
            if ([delegate respondsToSelector:@selector(gridViewCellDidStartDragging:)]) {
                [delegate gridViewCellDidStartDragging:self];
            }
        }
    }
    
    if (dragging) {
        CGPoint location = [touch locationInView:self.superview];
        
        self.center = CGPointMake(location.x - dragAnchorPoint.x,
                                  location.y - dragAnchorPoint.y);
        
        if ([delegate respondsToSelector:@selector(gridViewCell:didDragToCenter:touchLocation:)]) {
            [delegate gridViewCell:self didDragToCenter:self.center touchLocation:location];
        }
    }
}

@end
