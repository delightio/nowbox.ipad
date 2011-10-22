//
//  CategoryCellView.m
//  ipad
//
//  Created by Tim Chen on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategoryCellView.h"

@implementation CategoryCellView

@synthesize highlighted;
@synthesize selected;
@synthesize categoryText;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setCategoryText:(NSString *)newText {
    if (categoryText != newText) {
        [categoryText release];
        categoryText = [newText retain];
    }
    
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)lit {
	highlighted = lit;
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)isSelected {
    selected = isSelected;
    [self setNeedsDisplay];
}

- (void)dealloc {
    [categoryText release];
    
    [super dealloc];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rectangle = self.frame;
    
    if (self.selected) {
        [[UIImage imageNamed:@"category-list-selected-left"] drawInRect:CGRectMake(0, 0, 4, 70)];
        [[UIImage imageNamed:@"category-list-selected-mid"] drawInRect:CGRectMake(4, 0, rectangle.size.width-8, 70)];
        [[UIImage imageNamed:@"category-list-selected-right"] drawInRect:CGRectMake(rectangle.size.width-4, 0, 4, 70)];
        [[UIImage imageNamed:@"category-list-selected-arrow"] drawInRect:CGRectMake((rectangle.size.width-22)/2, 60, 22, 10)];        
    } else if (self.highlighted) {
        [[UIImage imageNamed:@"category-list-normal-bg"] drawInRect:CGRectMake(0, 0, rectangle.size.width, 70)];        
        [[UIImage imageNamed:@"category-list-selected-left"] drawInRect:CGRectMake(0, 0, 4, 70) blendMode:kCGBlendModeNormal alpha:0.6];
        [[UIImage imageNamed:@"category-list-selected-mid"] drawInRect:CGRectMake(4, 0, rectangle.size.width-8, 70) blendMode:kCGBlendModeNormal alpha:0.6];
        [[UIImage imageNamed:@"category-list-selected-right"] drawInRect:CGRectMake(rectangle.size.width-4, 0, 4, 70) blendMode:kCGBlendModeNormal alpha:0.6];
    } else {
        [[UIImage imageNamed:@"category-list-normal-bg"] drawInRect:CGRectMake(0, 0, rectangle.size.width, 70)];
    }

    if (categoryText == nil) {
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        
        if ( NM_RUNNING_IOS_5 ) {
            [@"MY" drawInRect:CGRectMake(4, 26, rectangle.size.width/2, 30) withFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            [@"MY" drawInRect:CGRectMake(4, 25, rectangle.size.width/2, 30) withFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        } else {
            [@"MY" drawInRect:CGRectMake(4, 26, rectangle.size.width/2, 30) withFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            [@"MY" drawInRect:CGRectMake(4, 25, rectangle.size.width/2, 30) withFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        }
        [[UIImage imageNamed:@"category-list-my-channels"] drawInRect:CGRectMake(39, 24, 26, 22)];
    } else if ([categoryText isEqualToString:@"<SEPARATOR>"]) {
        if (self.highlighted) {
            [[UIImage imageNamed:@"category-list-normal-bg"] drawInRect:CGRectMake(0, 0, 2, 70)];
        } else {
            [[UIImage imageNamed:@"category-list-separator"] drawInRect:CGRectMake(0, 0, 2, 70)];
        }
    }
    else {
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        
        if ( NM_RUNNING_IOS_5 ) {
            [[categoryText uppercaseString] drawInRect:CGRectMake(0, 26, rectangle.size.width, 30) withFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            [[categoryText uppercaseString] drawInRect:CGRectMake(0, 25, rectangle.size.width, 30) withFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        } else {
            [[categoryText uppercaseString] drawInRect:CGRectMake(0, 26, rectangle.size.width, 30) withFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            [[categoryText uppercaseString] drawInRect:CGRectMake(0, 25, rectangle.size.width, 30) withFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        }
    }
}

@end
