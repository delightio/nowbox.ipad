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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setCategoryText:(NSString *)newText {
    categoryTitle = newText;
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)lit {
	// If highlighted state changes, need to redisplay.
	if (highlighted != lit) {
		highlighted = lit;	
		[self setNeedsDisplay];
	}
}

- (void)dealloc {
    [super dealloc];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rectangle = self.frame;
    
    if (self.highlighted) {
        [[UIImage imageNamed:@"category-list-selected-left"] drawInRect:CGRectMake(0, 0, 4, 59)];
        [[UIImage imageNamed:@"category-list-selected-mid"] drawInRect:CGRectMake(4, 0, rectangle.size.width-8, 59)];
        [[UIImage imageNamed:@"category-list-selected-right"] drawInRect:CGRectMake(rectangle.size.width-4, 0, 4, 59)];
        [[UIImage imageNamed:@"category-list-selected-arrow"] drawInRect:CGRectMake((rectangle.size.width-18)/2, 53, 18, 6)];
    } else {
        [[UIImage imageNamed:@"category-list-normal-bg"] drawInRect:CGRectMake(0, 0, rectangle.size.width, 59)];
    }
    
    if (categoryTitle == nil) {
        [[UIImage imageNamed:@"category-list-my-channels"] drawInRect:CGRectMake(15, 21, 30, 17)];
    } else {
        CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
        
        [[categoryTitle uppercaseString] drawInRect:CGRectMake(0, 20, rectangle.size.width, 30) withFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
    }
}

@end
