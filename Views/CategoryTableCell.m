//
//  CategoryTableCell.m
//  ipad
//
//  Created by Tim Chen on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategoryTableCell.h"
#import "CategoryCellView.h"

@implementation CategoryTableCell

@synthesize categoryView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        categoryView = [[CategoryCellView alloc]initWithFrame:CGRectMake(0, 0, 150, 70)];
        [self.contentView addSubview:categoryView];
//        [self setClipsToBounds:YES];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [categoryView setHighlighted:highlighted];
    [super setHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected {
    [categoryView setSelected:selected];
    [super setSelected:selected];    
}

-(void)setCategoryTitle:(NSString *)newTitle {
    [categoryView setCategoryText:newTitle];
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    frame.size = CGSizeMake(frame.size.height, frame.size.width);
    frame.origin = CGPointMake(0, 0);
    [categoryView setFrame:frame];
}

- (void)redisplay {
	[categoryView setNeedsDisplay];
}


- (void)dealloc {
	[categoryView release];
    [super dealloc];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    CategoryTableCell *clonedCell = [[CategoryTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.reuseIdentifier];
    [clonedCell setCategoryTitle:categoryView.categoryText];
    [clonedCell setHighlighted:self.highlighted];
    [clonedCell setSelected:self.selected];
    [clonedCell setFrame:self.frame];    
    [clonedCell redisplay];
    
    return clonedCell;
}

@end
