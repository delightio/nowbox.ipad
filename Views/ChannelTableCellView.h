//
//  ChannelTableCellView.h
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ChannelTableCellView : UITableViewCell {
	NSArray * channels;
}

@property (nonatomic, retain) NSArray * channels;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
