//
//  VideoViewController.h
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoInfoView.h"
#import "NMChannel.h"
#import "NMVideo.h"

@interface VideoViewController : UIViewController

@property (nonatomic, retain) IBOutlet VideoInfoView *portraitView;
@property (nonatomic, retain) IBOutlet VideoInfoView *landscapeView;
@property (nonatomic, retain) NMChannel *channel;
@property (nonatomic, retain) NMVideo *video;

- (id)initWithChannel:(NMChannel *)channel video:(NMVideo *)video nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)gridButtonPressed:(id)sender;

@end
