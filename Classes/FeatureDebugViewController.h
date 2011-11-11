//
//  SearchDebugViewController.h
//  ipad
//
//  Created by Bill So on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"

@class VideoPlaybackViewController;

@interface FeatureDebugViewController : UIViewController <NSFetchedResultsControllerDelegate> {
	IBOutlet UIButton * subscribeButton;

	NMChannel * targetChannel;
	NMChannel * selectedChannel;
	VideoPlaybackViewController * playbackViewController;
}

@property (nonatomic, retain) NMChannel * targetChannel;
@property (nonatomic, retain) NMChannel * selectedChannel;
@property (nonatomic, retain) VideoPlaybackViewController * playbackViewController;

- (IBAction)resetTooltip:(id)sender;
- (IBAction)getDebugChannel:(id)sender;
- (IBAction)checkUpdate:(id)sender;
- (IBAction)bulkSubscibe:(id)sender;
- (IBAction)renewToken:(id)sender;
- (IBAction)checkTokenExpiryAndRenew:(id)sender;
- (IBAction)pollUserYouTube:(id)sender;

@end
