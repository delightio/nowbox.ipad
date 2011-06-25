//
//  ChannelTableCellView.h
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChannelNameBackgroundView;

@interface ChannelTableCellView : UITableViewCell {
	ChannelNameBackgroundView * channelBackgroundView;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
