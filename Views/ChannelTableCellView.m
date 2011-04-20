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
#import "NMCacheController.h"


#define NM_CHANNEL_CELL_MARGIN		44.0f
#define NM_CHANNEL_CELL_LEFT_PADDING	76.0f

@implementation ChannelTableCellView

@synthesize channels, delegate;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // create 3 image views
		CGRect theFrame;// = CGRectMake(11.0, 13.0, 248.0, 174.0);
		//TODO: replace image view with one that support caching
//		UIImage * img = [UIImage imageNamed:@"channel_border"];
//		UIImageView * iv;
//		UILabel * lbl;
		NMTouchImageView * tiv;
		CGFloat idx = 0.0;
//		UIFont * ft = [UIFont fontWithName:@"Futura-MediumItalic" size:15.0f];
//		UIColor * clearColor = [UIColor clearColor];
//		UIColor * whiteColor = [UIColor whiteColor];
//		UIColor * blackColor = [UIColor blackColor];
		for (NSInteger i = 0; i < 3; i++) {
//			borderFrame.origin.x = idx * (275.0 + NM_CHANNEL_CELL_MARGIN);
//			iv = [[UIImageView alloc] initWithFrame:borderFrame];
//			iv.image = img;
//			iv.tag = 2000 + i;
//			[self.contentView addSubview:iv];
//			[iv release];
			
			tiv = [[NMTouchImageView alloc] init];
			theFrame = tiv.frame;
			theFrame.origin.x = idx * (theFrame.size.width + NM_CHANNEL_CELL_MARGIN) + NM_CHANNEL_CELL_LEFT_PADDING;
			tiv.frame = theFrame;
			tiv.tag = 1000 + i;
			[self.contentView addSubview:tiv];
			[tiv addTarget:self action:@selector(channelTouchUp:)];
			[tiv release];
			
//			lbl = [[UILabel alloc] initWithFrame:CGRectMake(idx * (275.0 + NM_CHANNEL_CELL_MARGIN) + 15.0, 12.0f, 275.0f, 22.0f)];
//			lbl.tag = 3000 + i;
//			lbl.font = ft;
//			lbl.shadowOffset = CGSizeMake(0.0, 1.0f);
//			lbl.shadowColor = blackColor;
//			lbl.backgroundColor = clearColor;
//			lbl.textColor = whiteColor;
//			[self.contentView addSubview:lbl];
//			[lbl release];
			
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
	NMTouchImageView * imv;
	NMCacheController * cacheCtrl = [NMCacheController sharedCacheController];
	for (chan in chns) {
		// update thumbnail
		imv = (NMTouchImageView *)[self.contentView viewWithTag:1000 + i];
		[cacheCtrl setImageInChannel:chan forImageView:imv];
		// channel name
		imv.channelName = chan.title;
		if ( imv.hidden ) {
			imv.hidden = NO;
		}
		i++;
	}
	// hide the rest of the views
	if ( i < 3 ) {
		for (i; i < 3; i++) {
			imv = (NMTouchImageView *)[self.contentView viewWithTag:1000 + i];
			imv.hidden = YES;
			imv.image = nil;
//			[self.contentView viewWithTag:2000 + i].hidden = YES;
//			[self.contentView viewWithTag:3000 + i].hidden = YES;
		}
	}
}


- (void)dealloc {
	[channels release];
    [super dealloc];
}


@end
