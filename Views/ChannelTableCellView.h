//
//  ChannelTableCellView.h
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChannelTableCellView;

@protocol ChannelTableCellDelegate <NSObject>

- (void)tableViewCell:(ChannelTableCellView *)cell didSelectChannelAtIndex:(NSUInteger)index;

@end


@interface ChannelTableCellView : UITableViewCell {
	NSArray * channels;
	id <ChannelTableCellDelegate> delegate;
}

@property (nonatomic, retain) NSArray * channels;
@property (nonatomic, assign) id<ChannelTableCellDelegate> delegate;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
