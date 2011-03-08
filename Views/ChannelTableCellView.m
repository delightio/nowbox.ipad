//
//  ChannelTableCellView.m
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChannelTableCellView.h"
#import "NMChannel.h"


@implementation ChannelTableCellView

@synthesize channels;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // create 3 image views
		CGRect theFrame = CGRectMake(0.0, 0.0, 260.0, 194.0);
		//TODO: replace image view with one that support caching
		UIImageView * iv;
		CGFloat idx = 0.0;
		for (NSInteger i = 0; i < 3; i++) {
			theFrame.origin.x = idx * 260.0;
			iv = [[UIImageView alloc] initWithFrame:theFrame];
			iv.tag = 1000 + i;
			[self.contentView addSubview:iv];
			[iv release];
			idx += 1.0;
		}
    }
    return self;
}


//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    
//    [super setSelected:selected animated:animated];
//    
//    // Configure the view for the selected state.
//}

- (void)setChannels:(NSArray *)chns {
	NMChannel * chan;
	NSInteger i = 0;
	UIImageView * imv;
	for (chan in chns) {
		imv = (UIImageView *)[self.contentView viewWithTag:1000 + i];
		imv.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:chan.thumbnail]]];
		if ( imv.hidden ) imv.hidden = NO;
		i++;
	}
	// hide the rest of the views
	if ( i < 3 ) {
		for (i = 3 - i; i < 3; i++) {
			imv = (UIImageView *)[self.contentView viewWithTag:1000 + i];
			imv.hidden = YES;
			imv.image = nil;
		}
	}
}


- (void)dealloc {
	[channels release];
    [super dealloc];
}


@end
