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
	IBOutlet UIActivityIndicatorView * syncActivityView;

	NMChannel * targetChannel;
	NMChannel * selectedChannel;
	VideoPlaybackViewController * playbackViewController;
}

@property (nonatomic, retain) NMChannel * targetChannel;
@property (nonatomic, retain) NMChannel * selectedChannel;
@property (nonatomic, retain) VideoPlaybackViewController * playbackViewController;

- (IBAction)checkUpdate:(id)sender;
- (IBAction)bulkSubscibe:(id)sender;
- (IBAction)renewToken:(id)sender;
- (IBAction)checkTokenExpiryAndRenew:(id)sender;
- (IBAction)pollUserYouTube:(id)sender;
- (IBAction)getSubscribedChannels:(id)sender;
- (IBAction)syncRequest:(id)sender;
- (IBAction)printCommandIndexPool:(id)sender;
- (IBAction)printMovieViewInfo:(id)sender;
- (IBAction)importYouTube:(id)sender;
- (IBAction)facebookFilter:(id)sender;
- (IBAction)facebookSignOut:(id)sender;
- (IBAction)facebookFeedParse:(id)sender;
- (IBAction)facebookRefreshToken:(id)sender;
- (IBAction)twitterFilter:(id)sender;

@end
