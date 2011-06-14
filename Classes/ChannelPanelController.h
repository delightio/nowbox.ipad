//
//  ChannelPanelController.h
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChannelPanelController : NSObject {
    IBOutlet UITableView * tableView;
	UIView *panelView;
}

@property (nonatomic, retain) IBOutlet UIView *panelView;

- (IBAction)toggleTableEditMode:(id)sender;
- (IBAction)debugRefreshChannel:(id)sender;

@end
