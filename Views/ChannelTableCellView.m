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


#define NM_CHANNEL_CELL_MARGIN		16.0f

@implementation ChannelTableCellView

@synthesize channels, delegate;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // create 3 image views
		CGRect theFrame = CGRectMake(11.0, 13.0, 248.0, 174.0);
		CGRect borderFrame = CGRectMake(0.0, 0.0, 275.0, 218.0);
		//TODO: replace image view with one that support caching
		UIImage * img = [UIImage imageNamed:@"channel_border"];
		UIImageView * iv;
		UILabel * lbl;
		NMTouchImageView * tiv;
		CGFloat idx = 0.0;
		UIFont * ft = [UIFont fontWithName:@"Futura-MediumItalic" size:15.0f];
		UIColor * clearColor = [UIColor clearColor];
		UIColor * whiteColor = [UIColor whiteColor];
		UIColor * blackColor = [UIColor blackColor];
		for (NSInteger i = 0; i < 3; i++) {
			borderFrame.origin.x = idx * (275.0 + NM_CHANNEL_CELL_MARGIN);
			iv = [[UIImageView alloc] initWithFrame:borderFrame];
			iv.image = img;
			iv.tag = 2000 + i;
			[self.contentView addSubview:iv];
			[iv release];
			
			theFrame.origin.x = idx * (275.0 + NM_CHANNEL_CELL_MARGIN) + 11.0;
			tiv = [[NMTouchImageView alloc] initWithFrame:theFrame];
			tiv.tag = 1000 + i;
			[self.contentView addSubview:tiv];
			[tiv addTarget:self action:@selector(channelTouchUp:)];
			[tiv release];
			
			lbl = [[UILabel alloc] initWithFrame:CGRectMake(idx * (275.0 + NM_CHANNEL_CELL_MARGIN) + 15.0, 12.0f, 275.0f, 22.0f)];
			lbl.tag = 3000 + i;
			lbl.font = ft;
			lbl.shadowOffset = CGSizeMake(0.0, 1.0f);
			lbl.shadowColor = blackColor;
			lbl.backgroundColor = clearColor;
			lbl.textColor = whiteColor;
			[self.contentView addSubview:lbl];
			[lbl release];
			
			idx += 1.0;
		}
    }
    return self;
}

- (void)channelTouchUp:(id)sender {
	NMTouchImageView * tiv = (NMTouchImageView *)sender;
	if ( delegate ) {
		[delegate tableViewCell:self didSelectChannelAtIndex:tiv.tag - 1000];
	}
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
	UILabel * lbl;
	for (chan in chns) {
		imv = (UIImageView *)[self.contentView viewWithTag:1000 + i];
		imv.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:chan.thumbnail]]];
		lbl = (UILabel *)[self.contentView viewWithTag:3000 + i];
		lbl.text = chan.title;
		if ( imv.hidden ) {
			imv.hidden = NO;
			[self.contentView viewWithTag:2000 + i].hidden = NO;
			lbl.hidden = NO;
		}
		i++;
	}
	// hide the rest of the views
	if ( i < 3 ) {
		for (i; i < 3; i++) {
			imv = (UIImageView *)[self.contentView viewWithTag:1000 + i];
			imv.hidden = YES;
			imv.image = nil;
			[self.contentView viewWithTag:2000 + i].hidden = YES;
			[self.contentView viewWithTag:3000 + i].hidden = YES;
		}
	}
}


- (void)dealloc {
	[channels release];
    [super dealloc];
}


@end
