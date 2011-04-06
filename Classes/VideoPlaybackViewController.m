//
//  VideoPlaybackViewController.m
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "SocialSignInViewController.h"
#import "NMLibrary.h"
#import "NMVideo.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>


#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT		101
#define RRIndex(idx) idx % 4

@interface VideoPlaybackViewController (PrivateMethods)

- (void)insertVideoAtIndex:(NSUInteger)idx;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewAtIndex:(NSInteger)idx;

@end


@implementation VideoPlaybackViewController
@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;
@synthesize currentIndexPath=currentIndexPath_;
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize loadedControlView;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	self.wantsFullScreenLayout = YES;
	isAspectFill = YES;
	firstShowControlView = YES;
	
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	// pre-load some control view
	NSBundle * mb = [NSBundle mainBundle];
	controlViewArray = [[NSMutableArray alloc] initWithCapacity:4]; // 4 in total, 1 for prev, 1 for current, 2 for upcoming
	for (NSInteger i = 0; i < 4; i++) {
		[mb loadNibNamed:@"VideoControlView" owner:self options:nil];
		[loadedControlView addTarget:self action:@selector(controlsViewTouchUp:)];
		[controlViewArray addObject:loadedControlView];
	}
	
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:self.view.bounds];
	movieView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:movieView];
	
	NSNotificationCenter * dc = [NSNotificationCenter defaultCenter];
	[dc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	[dc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	
	// setup gesture recognizer
	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewZoom:)];
	[movieView addGestureRecognizer:pinRcr];
	[pinRcr release];
	// set target-action methods
	[movieView addTarget:self action:@selector(movieViewTouchUp:)];
	
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	NSUInteger c = [sectionInfo numberOfObjects];
	if ( c ) {
		// we should play video at currentIndex
		// get the direct URL
		[nowmovTaskController issueGetDirectURLForVideo:[self.fetchedResultsController objectAtIndexPath:self.currentIndexPath]];
		[self configureControlViewAtIndex:currentIndex];
		//TODO: configure other view
		if ( currentIndex ) {
			[self configureControlViewAtIndex:currentIndex - 1];
		}
		if ( currentIndex + 1 < c )	[self configureControlViewAtIndex:currentIndex + 1];
		if ( currentIndex + 2 < c ) [self configureControlViewAtIndex:currentIndex + 2];
		//TODO: check if need to queue fetch video list
	} else {
		// there's no video. fetch video right now
		freshStart = YES;
		NMTaskQueueController * ctrl = nowmovTaskController;
//		[ctrl.dataController deleteAllVideos];
		// get videos from server
		[ctrl issueGetLiveChannel];
//		[nowmovTaskController issueGetVideoListForChannel:currentChannel isNew:YES];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	}
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
	[currentIndexPath_ release];
	
	[movieView release];
	[progressView release];
	[currentChannel release];
    [super dealloc];
}

- (NSIndexPath *)currentIndexPath {
	if ( currentIndexPath_ == nil ) {
		currentIndexPath_ = [[NSIndexPath indexPathForRow:currentIndex inSection:0] retain];
	} else if ( currentIndexPath_.row != currentIndex ) {
		[currentIndexPath_ release];
		currentIndexPath_ = [[NSIndexPath indexPathForRow:currentIndex inSection:0] retain];
	}
	
	return currentIndexPath_;
}

#pragma mark Playback Control

- (void)stopVideo {
	[movieView.player pause];
}

- (void)playVideo {
	if ( movieView.player.rate == 0.0 ) {
		[movieView.player play];
	}
}

- (IBAction)playStopVideo:(id)sender {
	if ( movieView.player.rate == 0.0 ) {
		[movieView.player play];
	} else {
		[movieView.player pause];
	}
}

#pragma mark Movie View Management
- (void)preparePlayer {
	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:self.currentIndexPath];
	AVQueuePlayer * player = [[AVQueuePlayer alloc] initWithItems:[NSArray arrayWithObject:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]]]];
	movieView.player = player;
	// observe status change in player
	[player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
	[player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
	[player addPeriodicTimeObserverForInterval:CMTimeMake(2, 2) queue:NULL usingBlock:^(CMTime aTime){
		// print the time
		CMTime t = [player currentTime];
		[self setCurrentTime:t.value / t.timescale];
	}];
	// listen to item finish up playing notificaiton
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	// player layer
	[player play];
	
	// get other video's direct URL
	[self requestAddVideoAtIndex:currentIndex + 1];
	[self requestAddVideoAtIndex:currentIndex + 2];
}

- (void)configureControlViewAtIndex:(NSInteger)idx {
	NMControlsView * mv = [controlViewArray objectAtIndex:RRIndex(idx)];
	// set title and stuff
	NMVideo * v = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
	mv.title = v.title;
	mv.authorProfileURLString = v.author_profile_link;
	[mv resetProgressView];
	[mv setChannel:v.channel.channel_name author:v.author_username];
	[mv setControlsHidden:YES animated:NO];
}

#pragma mark Video queuing

- (void)requestAddVideoAtIndex:(NSUInteger)idx {
	// request to add the video to queue. If the direct URL does not exists, fetch from the server
	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
	if ( vid.nm_direct_url == nil || [vid.nm_direct_url isEqualToString:@""] ) {
		[nowmovTaskController issueGetDirectURLForVideo:vid];
//		[self getVideoInfoAtIndex:idx];
	} else {
		[self insertVideoAtIndex:idx];
//		[self getVideoInfoAtIndex:idx];
	}
}

- (void)insertVideoAtIndex:(NSUInteger)idx {
	// buffer the next next video
	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
	AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]];
	if ( [movieView.player canInsertItem:item afterItem:nil] ) {
		[movieView.player insertItem:item afterItem:nil];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"added video to queue player: %d", idx);
#endif
	}
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	else {
		NSLog(@"can't add video to queue player: %d", idx);
	}
#endif
}

//- (void)getVideoInfoAtIndex:(NSUInteger)idx {
//	NMVideo * v = [sortedVideoList objectAtIndex:idx];
//	// check if video info already exists
//	if ( v.title == nil ) {
//		[nowmovTaskController issueGetVideoInfo:v];
//	}
//}

#pragma mark Notification handling
- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	if ( movieView.player == nil ) {
		[self preparePlayer];
	} else {
		// check if we need to queue the video to player
		NMVideo * vid = [[aNotification userInfo] objectForKey:@"target_object"];
		NSUInteger i = [self.fetchedResultsController indexPathForObject:vid].row;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"resolved URL for idx: %d", i);
#endif
		if ( i - currentIndex < 3 ) {
			// queue the item
			[self insertVideoAtIndex:i];
		}
	}
}

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
	currentIndex++;
//	[self updateControlsForVideoAtIndex:currentIndex];
	[self requestAddVideoAtIndex:currentIndex + 2];
}

- (void)handleDidGetVideoListNotification:(NSNotification *)aNotification {
	// don't do anything for now. when a new video list is saved in MOC. the fetched results controller will call its delegate to handle the data change.
}

//- (void)handleDidGetVideoInfoNotification:(NSNotification *)aNotification {
//	NMVideo * v = [[aNotification userInfo] objectForKey:@"target_object"];
//	NSUInteger i = [sortedVideoList indexOfObject:v];
//	if ( i == currentIndex ) {
//		// update the interface
//		[self updateControlsForVideoAtIndex:currentIndex];
//	}
//}
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (movieView.player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				// the instance is ready to play. yeah!
				//[self updateControlsForVideoAtIndex:currentIndex];
				if ( firstShowControlView ) {
					firstShowControlView = NO;
//					if ( !controlsContainerView.hidden && controlsContainerView.alpha > 0.0 ) {
//						// hide the control
//						[self controlsViewTouchUp:nil];
//					}
				}
				break;
			}
			default:
				break;
		}
		if ( firstShowControlView ) {
			firstShowControlView = NO;
		}
	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"current item changed");
#endif
		[self updateControlsForVideoAtIndex:currentIndex];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)handleMovieViewZoom:(id)sender {
	UIPinchGestureRecognizer * rcr = (UIPinchGestureRecognizer *)sender;
	NSLog(@"s %f v %f", rcr.scale, rcr.velocity);
	CGRect theFrame;
	CGSize theSize;
	if ( rcr.velocity > 0 && rcr.scale > 1.2 && isAspectFill ) {
		// scale the player layer down
		isAspectFill = NO;
		theFrame = movieView.bounds;
		// calculate the size
		theSize = movieView.player.currentItem.presentationSize;
		theSize.width = floorf(768.0 / theSize.height * theSize.width);
		theSize.height = 768.0;
		theFrame.size = theSize;
		movieView.bounds = theFrame;
	} else if ( rcr.velocity < 0 && rcr.scale < 0.8 && !isAspectFill ) {
		isAspectFill = YES;
		// restore the original size
		theFrame = self.view.bounds;
		movieView.bounds = theFrame;
	}
}

#pragma mark Playback view UI update
- (void)setCurrentTime:(NSInteger)sec {
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
	if ( videoDurationInvalid ) {
		CMTime t = movieView.player.currentItem.asset.duration;
		if ( t.flags & kCMTimeFlags_Valid ) {
			NSInteger sec = t.value / t.timescale;
			totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
			videoDurationInvalid = NO;
		}
	}
}

- (void)updateControlsForVideoAtIndex:(NSUInteger)idx {
	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//	channelNameLabel.text = [currentChannel.channel_name capitalizedString];
//	videoTitleLabel.text = [vid.title uppercaseString];
	CMTime t = movieView.player.currentItem.asset.duration;
	// check if the time is value
	if ( t.flags & kCMTimeFlags_Valid ) {
		NSInteger sec = t.value / t.timescale;
		totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
	} else {
		videoDurationInvalid = YES;
	}
}

#pragma mark Popover delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self playVideo];
}

#pragma mark Target-action methods

//- (IBAction)showTweetView:(id)sender {
//	if ( infoPanelImageView == nil ) {
//		UIButton * btn = (UIButton *)sender;
//		UIImage * img = [UIImage imageNamed:@"info_panel"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
//		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
//		infoPanelImageView = [[UIImageView alloc] initWithImage:img];
//		infoPanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:infoPanelImageView];
//	} else {
//		[infoPanelImageView removeFromSuperview];
//		[infoPanelImageView release];
//		infoPanelImageView = nil;
//	}
//}
//
//- (IBAction)showVolumeControlView:(id)sender {
//	if ( volumePanelImageView == nil ) {
//		UIButton * btn = (UIButton *)sender;
//		UIImage * img = [UIImage imageNamed:@"volume_panel"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
//		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
//		volumePanelImageView = [[UIImageView alloc] initWithImage:img];
//		volumePanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:volumePanelImageView];
//	} else {
//		[volumePanelImageView removeFromSuperview];
//		[volumePanelImageView release];
//		volumePanelImageView = nil;
//	}
//}
//
//- (IBAction)showShareActionView:(id)sender {
//	if ( shareVideoPanelImageView == nil ) {
//		UIImage * img = [UIImage imageNamed:@"twitter_share_popup"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.x = floorf( (1024.0 - img.size.width) / 2.0 );
//		theFrame.origin.y = floorf( ( 768.0 - img.size.height ) / 2.0 );
//		shareVideoPanelImageView = [[UIImageView alloc] initWithImage:img];
//		shareVideoPanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:shareVideoPanelImageView];
//	} else {
//		[shareVideoPanelImageView removeFromSuperview];
//		[shareVideoPanelImageView release];
//		shareVideoPanelImageView = nil;
//	}
//}
//
- (IBAction)backToChannelView:(id)sender {
	[movieView.player pause];
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)setLikeVideo:(id)sender {
	
}

- (IBAction)skipCurrentVideo:(id)sender {
	UIView * btn = (UIView *)sender;
	if ( btn.tag == 1000 ) {
		// prev
	} else {
		// next
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
		NSUInteger c = [sectionInfo numberOfObjects];
		if ( currentIndex + 2 < c ) {
			// buffer the next next video
			[self requestAddVideoAtIndex:currentIndex + 2];
		}
		if ( currentIndex < c ) {
			currentIndex++;
		}
		[movieView.player advanceToNextItem];
	}
}

- (IBAction)showSharePopover:(id)sender {
	UIButton * btn = (UIButton *)sender;
	
	SocialSignInViewController * socialCtrl = [[SocialSignInViewController alloc] initWithNibName:@"SocialSignInView" bundle:nil];
	socialCtrl.videoViewController = self;
	
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:socialCtrl];
	
	UIPopoverController * popCtrl = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	popCtrl.popoverContentSize = CGSizeMake(320.0f, 154.0f);
	popCtrl.delegate = self;
	
	[popCtrl presentPopoverFromRect:btn.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	
	[socialCtrl release];
	[navCtrl release];
}

- (void)movieViewTouchUp:(id)sender {
	// show the control view
	[UIView beginAnimations:nil context:nil];
//	controlsContainerView.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)controlsViewTouchUp:(id)sender {
	// hide the control view
	[UIView beginAnimations:nil context:nil];
//	controlsContainerView.alpha = 0.0;
	[UIView commitAnimations];
}

#pragma mark Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}    

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
	NSUInteger numVideos = [sectionInfo numberOfObjects];
	if ( numVideos == 0 ) {
		return;
	}
	
	if ( freshStart ) {
		// launching the app with empty video list.
		// now, get the direct url for some videos
		[nowmovTaskController issueGetDirectURLForVideo:[self.fetchedResultsController objectAtIndexPath:self.currentIndexPath]];
		// purposely don't queue fetch direct URL for other video in the list to avoid too much network traffic. Delay this till the video starts playing
		freshStart = NO;
		[self configureControlViewAtIndex:currentIndex];
		[self configureControlViewAtIndex:currentIndex + 1];
		[self configureControlViewAtIndex:currentIndex + 2];
	} else {
		// check if we need to get the direct URL
	}
}

@end
