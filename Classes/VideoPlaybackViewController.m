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
#import "NMMovieView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define NM_PLAYER_STATUS_CONTEXT				100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT			101
#define NM_PLAYBACK_BUFFER_EMPTY_CONTEXT		102
#define NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT	103
#define NM_LOADED_TIME_RANGES_CONTEXT			104
#define NM_MAX_VIDEO_IN_QUEUE				3
#define NM_INDEX_PATH_CACHE_SIZE			4

#define NM_PLAYER_SCROLLVIEW_ANIMATION_CONTEXT	200

typedef enum {
	NMVideoQueueStatusNone,
	NMVideoQueueStatusResolvingDirectURL,
	NMVideoQueueStatusDirectURLReady,
	NMVideoQueueStatusQueued,
	NMVideoQueueStatusPlaying,
	NMVideoQueueStatusPlayed,
} NMVideoQueueStatusType;

#define RRIndex(idx) idx % 4

@interface VideoPlaybackViewController (PrivateMethods)

//- (void)insertVideoAtIndex:(NSUInteger)idx;
//- (void)queueVideoToPlayer:(NMVideo *)vid;
- (void)playerQueueVideos;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewAtIndex:(NSInteger)idx;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)translateMovieViewByOffset:(CGFloat)offset;

// index path cache
- (NSIndexPath *)indexPathAtIndex:(NSUInteger)idx;
- (void)freeIndexPathCache;

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
	
	indexPathCache = CFAllocatorAllocate(NULL, sizeof(NSIndexPath *) * NM_INDEX_PATH_CACHE_SIZE, 0);
	bzero(indexPathCache, sizeof(NSIndexPath *) * NM_INDEX_PATH_CACHE_SIZE);
	
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:controlScrollView.bounds];
	movieView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[controlScrollView addSubview:movieView];
	
	// pre-load some control view
	CGRect theFrame;
	NSBundle * mb = [NSBundle mainBundle];
	controlViewArray = [[NSMutableArray alloc] initWithCapacity:4]; // 4 in total, 1 for prev, 1 for current, 2 for upcoming
	for (CGFloat i = 0.0; i < 4.0; i += 1.0) {
		// load the nib
		[mb loadNibNamed:@"VideoControlView" owner:self options:nil];
		// hook up with target-action
		[loadedControlView addTarget:self action:@selector(controlsViewTouchUp:)];
		[loadedControlView.channelViewButton addTarget:self action:@selector(backToChannelView:) forControlEvents:UIControlEventTouchUpInside];
		[loadedControlView.shareButton addTarget:self action:@selector(showSharePopover:) forControlEvents:UIControlEventTouchUpInside];
		[loadedControlView.playPauseButton addTarget:self action:@selector(playStopVideo:) forControlEvents:UIControlEventTouchUpInside];
		[loadedControlView.nextVideoButton addTarget:self action:@selector(skipCurrentVideo:) forControlEvents:UIControlEventTouchUpInside];
		[loadedControlView.voteDownButton addTarget:self action:@selector(vote:) forControlEvents:UIControlEventTouchUpInside];
		[loadedControlView.voteUpButton addTarget:self action:@selector(vote:) forControlEvents:UIControlEventTouchUpInside];
		
		[controlViewArray addObject:loadedControlView];
		// put the view to scroll view
		theFrame = loadedControlView.frame;
		theFrame.origin.x = i * theFrame.size.width;
		loadedControlView.frame = theFrame;
		[controlScrollView addSubview:loadedControlView];
	}
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMDidFailGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMURLConnectionErrorNotification object:nil];
	// listen to item finish up playing notificaiton
	[nc addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	
	// setup gesture recognizer
	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewPinched:)];
//	[movieView addGestureRecognizer:pinRcr];
	[controlScrollView addGestureRecognizer:pinRcr];
	[pinRcr release];
	// set target-action methods
	[movieView addTarget:self action:@selector(movieViewTouchUp:)];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	movieView.player = nil;
	currentIndex = 0;
	firstShowControlView = YES;
	// reset player position
	CGRect theFrame = movieView.frame;
	theFrame.origin.x = 0.0f;
	movieView.frame = theFrame;
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
	[self freeIndexPathCache];
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
	[currentIndexPath_ release];
	
	[movieView release];
	[currentChannel release];
    [super dealloc];
}

- (NSIndexPath *)currentIndexPath {
	if ( currentIndexPath_ == nil ) {
		currentIndexPath_ = [[self indexPathAtIndex:currentIndex] retain];
	} else if ( currentIndexPath_.row != currentIndex ) {
		[currentIndexPath_ release];
		currentIndexPath_ = [[self indexPathAtIndex:currentIndex] retain];
	}
	
	return currentIndexPath_;
}

- (void)setCurrentChannel:(NMChannel *)chnObj {
	if ( currentChannel ) {
		if ( currentChannel != chnObj ) {
			[currentChannel release];
			currentChannel = [chnObj retain];
		}
	} else {
		currentChannel = [chnObj retain];
	}
	// reset fetch result
	self.fetchedResultsController = nil;
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	numberOfVideos = [sectionInfo numberOfObjects];
	
	// reset movie control view
	for (NMControlsView * ctrlView in controlViewArray) {
		[ctrlView resetView];
	}
	// update the video list
	if ( numberOfVideos ) {
		// we should play video at currentIndex
		// get the direct URL
		[self configureControlViewAtIndex:currentIndex];
		[self requestAddVideoAtIndex:currentIndex];
		//TODO: configure other view
		if ( currentIndex ) {
			[self configureControlViewAtIndex:currentIndex - 1];
			[self requestAddVideoAtIndex:currentIndex - 1];
		}
		if ( currentIndex + 1 < numberOfVideos )	{
			[self configureControlViewAtIndex:currentIndex + 1];
			[self requestAddVideoAtIndex:currentIndex + 1];
		}
		if ( currentIndex + 2 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 2];
			[self requestAddVideoAtIndex:currentIndex + 2];
		}
		controlScrollView.scrollEnabled = YES;
		controlScrollView.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
		
		//TODO: check if need to queue fetch video list
	} else {
		// there's no video. fetch video right now
		freshStart = YES;
		//		[nowmovTaskController issueGetVideoListForChannel:currentChannel isNew:YES];
		//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	}
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
	player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
	vid.nm_playback_status = NMVideoQueueStatusQueued;
	movieView.player = player;
	// observe status change in player
	[player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
	[player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
//	[player addObserver:self forKeyPath:@"currentItem.playbackLikelyToKeepUp" options:0 context:(void *)NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT];
//	[player addObserver:self forKeyPath:@"currentItem.playbackBufferEmpty" options:0 context:(void *)NM_PLAYBACK_BUFFER_EMPTY_CONTEXT];
//	[player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges" options:0 context:(void *)NM_LOADED_TIME_RANGES_CONTEXT];
	// all control view should observe to player changes
	for (NMControlsView * ctrlView in controlViewArray) {
		[player addObserver:ctrlView forKeyPath:@"rate" options:0 context:(void *)11111];
	}
	[player addPeriodicTimeObserverForInterval:CMTimeMake(2, 2) queue:NULL usingBlock:^(CMTime aTime){
		// print the time
		CMTime t = [movieView.player currentTime];
		NSInteger sec = 0;
		if ( t.flags & kCMTimeFlags_Valid ) {
			sec = t.value / t.timescale;
		}
		NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
		if ( videoDurationInvalid ) {
			t = movieView.player.currentItem.asset.duration;
			if ( t.flags & kCMTimeFlags_Valid ) {
#ifdef DEBUG_PLAYBACK_QUEUE
				NSLog(@"invalid time, get duration again: %lld", t.value / t.timescale);
#endif
				ctrlView.duration = t.value / t.timescale;
				videoDurationInvalid = NO;
			}
		}
		ctrlView.timeElapsed = sec;
		if ( firstShowControlView && (sec + 1) % 3 == 0) {
			firstShowControlView = NO;
			ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
			if ( !ctrlView.hidden && ctrlView.alpha > 0.0 ) {
				// hide the control
				[self controlsViewTouchUp:ctrlView];
			}
		}
	}];
	// player layer
	[player play];
	
	// check if we should other items into the player
	
	// =================
	// commented out because we are not sure i
	// get other video's direct URL
	[self requestAddVideoAtIndex:currentIndex + 1];
	[self requestAddVideoAtIndex:currentIndex + 2];
	// ====================
}

- (void)translateMovieViewByOffset:(CGFloat)offset {
	CGPoint pos = movieView.center;
	pos.x += movieView.bounds.size.width * offset;
	movieView.center = pos;
//	CGRect theFrame = movieView.frame;
//	theFrame.origin.x += theFrame.size.width * offset;
//	movieView.frame = theFrame;
}

- (void)showPlayerAndControl {
	controlScrollView.alpha = 1.0;	// don't perform transition yet
	controlScrollView.scrollEnabled = YES;
	didPlayToEnd = NO;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	NSInteger c = (NSInteger)context;
	switch (c) {
		case NM_PLAYER_SCROLLVIEW_ANIMATION_CONTEXT:
			currentIndex++;
			firstShowControlView = YES;
			// scroll to next video
			// translate the movie view
			[controlScrollView setContentOffset:CGPointMake(controlScrollView.contentOffset.x + controlScrollView.bounds.size.width, 0.0f) animated:NO];
			[self translateMovieViewByOffset:1.0f];
			
			[movieView.player advanceToNextItem];
			[movieView.player play];
			
			// update the movie control view
			if ( currentIndex + 2 < numberOfVideos ) {
				[self configureControlViewAtIndex:currentIndex + 2];
			} else {
				// get more video here
			}
			// make the view visible
			[self performSelector:@selector(showPlayerAndControl) withObject:nil afterDelay:0.1];
			break;
			
		default:
			break;
	}
}

#pragma mark Control Views Management
- (void)configureControlViewAtIndex:(NSInteger)idx {
	NMControlsView * mv = [controlViewArray objectAtIndex:RRIndex(idx)];
	// set title and stuff
	NMVideo * v = [self.fetchedResultsController objectAtIndexPath:[self indexPathAtIndex:idx]];
	[mv resetView];
	mv.title = v.title;
	mv.authorProfileURLString = v.author_profile_link;
	[mv setChannel:v.channel.title author:v.author_username];
	// update the position
	CGRect theFrame = mv.frame;
	theFrame.origin.x = (CGFloat)idx * theFrame.size.width;
	mv.frame = theFrame;
}

#pragma mark Video queuing
- (void)showNextVideo:(BOOL)aEndOfVideo {
	if ( currentIndex + 1 >= numberOfVideos ) {
		// there's no more video available
		//TODO: get more video here. issue fetch video list request
		
		return;
	}
	// send tracking event
	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
	[nowmovTaskController issueSendViewEventForVideo:[self.fetchedResultsController objectAtIndexPath:self.currentIndexPath] duration:ctrlView.duration elapsedSeconds:ctrlView.timeElapsed playedToEnd:aEndOfVideo];
	// visually transit to next video just like the user has tapped next button
	if ( aEndOfVideo ) {
		// disable interface scrolling
		// will activate again on "currentItem" change kvo notification
		controlScrollView.scrollEnabled = NO;
		// fade out the view
		[UIView beginAnimations:nil context:(void *)NM_PLAYER_SCROLLVIEW_ANIMATION_CONTEXT];
		controlScrollView.alpha = 0.0;
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView setAnimationDelegate:self];
		[UIView commitAnimations];
		// when traisition is done. move shift the scroll view and reveals the video player again
	} else {
		[controlScrollView setContentOffset:CGPointMake(controlScrollView.contentOffset.x + controlScrollView.bounds.size.width, 0.0f) animated:YES];
		[self translateMovieViewByOffset:1.0f];
		// advance the index
		currentIndex++;
		firstShowControlView = YES;	// change this together with currentIndex
		// show the next video in the player
		[movieView.player advanceToNextItem];
		[movieView.player play];
		// update the movie control view
		if ( currentIndex + 2 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 2];
		} else {
			// get more video here
		}
	}
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)requestAddVideoAtIndex:(NSUInteger)idx {
	if ( idx >= numberOfVideos ) return;
	// request to add the video to queue. If the direct URL does not exists, fetch from the server
	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[self indexPathAtIndex:idx]];
	if ( (vid.nm_direct_url == nil || [vid.nm_direct_url isEqualToString:@""]) ) {
		if ( vid.nm_playback_status == NMVideoQueueStatusNone ) {
	#ifdef DEBUG_PLAYBACK_NETWORK_CALL
			NSLog(@"issue resolve direct URL: %@", vid.title);
	#endif
			vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
			[nowmovTaskController issueGetDirectURLForVideo:vid];
		}
	} /*else if ( vid.nm_playback_status == NMVideoQueueStatusDirectURLReady ) {
		[self playerQueueVideos];
	}*/
}

- (void)playerQueueVideos {
	// creates player item and insert them into the queue orderly
	// don't queue any video for play if there's more than 3 queued
	NSUInteger c = [[movieView.player items] count];
	if ( c > NM_MAX_VIDEO_IN_QUEUE - 1 ) return;
	// since this method is called NOT-IN-ORDER, we should transverse the whole list to queue items
	NMVideo * vid;
	BOOL enableQueuing = YES;
	for ( NSInteger i = currentIndex + c; i < NM_MAX_VIDEO_IN_QUEUE + currentIndex; i++ ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"add/issue resolve items: %d", i);
#endif
		// check if there's enough video here to queue to.
		if ( i < numberOfVideos ) {
			vid = [self.fetchedResultsController objectAtIndexPath:[self indexPathAtIndex:i]];
			if ( enableQueuing ) {
				if ( vid.nm_playback_status == NMVideoQueueStatusDirectURLReady ) {
					// queue
					AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]];
					if ( [movieView.player canInsertItem:item afterItem:nil] ) {
						[movieView.player insertItem:item afterItem:nil];
						vid.nm_playback_status = NMVideoQueueStatusQueued;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
						NSLog(@"added video to queue player: %@, %@", vid.nm_sort_order, vid.title );
#endif
					}
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
					else {
						NSLog(@"can't add video to queue player: %@", vid.nm_sort_order);
					}
#endif
				} else if ( vid.nm_playback_status < NMVideoQueueStatusDirectURLReady ) {
					[self requestAddVideoAtIndex:i];
					// exit the loop. don't have to queue other video in the list. the queuing process must be in-order
					enableQueuing = NO;
				}
			} else {
				// just check if we should resolve the direct URL
				[self requestAddVideoAtIndex:i];
			}
		} else {
			break;
		}
	}
}
/*
- (void)queueVideoToPlayer:(NMVideo *)vid {
	// creates player item and insert them into the queue orderly
	// don't queue any video for play if there's more than 3 queued
	NSUInteger c = [[movieView.player items] count];
	if ( c > NM_MAX_VIDEO_IN_QUEUE - 1 ) return;
	// since this method is called NOT-IN-ORDER, we should transverse the whole list to queue items
	NSUInteger sortOrder = [vid.nm_sort_order unsignedIntegerValue];
	if ( sortOrder - currentIndex > NM_MAX_VIDEO_IN_QUEUE - 1 ) return;
	for (NSUInteger i = 0; i < sortOrder - currentIndex; i++) {
		if ( sortOrder == currentIndex + i + 1 ) {
			if ( vid.nm_playback_status == NMVideoQueueStatusDirectURLReady ) {
				// queue
				AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]];
				if ( [movieView.player canInsertItem:item afterItem:nil] ) {
					[movieView.player insertItem:item afterItem:nil];
					vid.nm_playback_status = NMVideoQueueStatusQueued;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
					NSLog(@"added video to queue player: %@, %@", vid.nm_sort_order, vid.title );
#endif
				}
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
				else {
					NSLog(@"can't add video to queue player: %@", vid.nm_sort_order);
				}
#endif
			}
		} else {
			NMVideo * theVid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:currentIndex + i + 1 inSection:0]];
			if ( [theVid.nm_sort_order integerValue] == currentIndex + i + 1 && theVid.nm_playback_status == NMVideoQueueStatusDirectURLReady ) {
				// queue
				AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:theVid.nm_direct_url]];
				if ( [movieView.player canInsertItem:item afterItem:nil] ) {
					[movieView.player insertItem:item afterItem:nil];
					theVid.nm_playback_status = NMVideoQueueStatusQueued;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
					NSLog(@"added video to queue player: %@, %@", theVid.nm_sort_order, theVid.title );
#endif
				}
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
				else {
					NSLog(@"can't add video to queue player: %@", theVid.nm_sort_order);
				}
#endif
			}
		}
	}
//	if ( c > 3 || vid.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) return;
//	for (NSUInteger i = 0; i < 3 - c; i++) {
//		// there's enough video stored in MOC
//		if ( currentIndex + i + 1 < numberOfVideos ) {
//			// check if there's URL
//			if ( [vid.nm_direct_url length] ) {
//				AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]];
//				if ( [movieView.player canInsertItem:item afterItem:nil] ) {
//					[movieView.player insertItem:item afterItem:nil];
//					vid.nm_playback_status = NMVideoQueueStatusQueued;
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//					NSLog(@"added video to queue player: %@, %@", vid.nm_sort_order, vid.title );
//#endif
//				}
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//				else {
//					NSLog(@"can't add video to queue player: %@", vid.nm_sort_order);
//				}
//#endif
//			}
//		}
//	}
}
*/
//- (void)insertVideoAtIndex:(NSUInteger)idx {
//	// buffer the next next video
//	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//	AVPlayerItem * item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]];
//	if ( [movieView.player canInsertItem:item afterItem:nil] ) {
//		[movieView.player insertItem:item afterItem:nil];
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//		NSLog(@"added video to queue player: %d", idx);
//#endif
//	}
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//	else {
//		NSLog(@"can't add video to queue player: %d", idx);
//	}
//#endif
//}

//- (void)getVideoInfoAtIndex:(NSUInteger)idx {
//	NMVideo * v = [sortedVideoList objectAtIndex:idx];
//	// check if video info already exists
//	if ( v.title == nil ) {
//		[nowmovTaskController issueGetVideoInfo:v];
//	}
//}

#pragma mark Notification handling
- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	NMVideo * vid = [[aNotification userInfo] objectForKey:@"target_object"];
	vid.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved: %@", vid.title);
#endif
	// check if we should queue the video resolved
	if ( movieView.player == nil ) {
		if ( currentIndex == [vid.nm_sort_order integerValue] )
			[self preparePlayer];
		// else - ignore the resolution result. we just want the first video
	} else {
		// check if we need to queue the video to player
		// queue the item
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"should queue video: %@", vid.title);
#endif
		[self playerQueueVideos];
	}
}

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"did play notification");
#endif
	didPlayToEnd = YES;
	[self showNextVideo:YES];
}

- (void)handleErrorNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
	if ( [[aNotification name] isEqualToString:NMDidFailGetYouTubeDirectURLNotification] ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"direct URL resolution failed: %@", [userInfo objectForKey:@"error"]);
#endif
		// skip the video by marking the resolution status
		if ( userInfo ) {
			NMVideo * vid = [userInfo objectForKey:@"target_object"];
			vid.nm_error = [userInfo objectForKey:@"errorNum"];
			[self.managedObjectContext save:nil];
		}
	} else if ( [[aNotification name] isEqualToString:NMURLConnectionErrorNotification] ) {
		// network error, we should retry
		NSLog(@"network error in resolving direct URL");
	} else if ( [[aNotification name] isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification] ) {
		NSLog(@"can't finish playing video. just skip it!");
		didPlayToEnd = YES;
		[self showNextVideo:YES];
	} else {
#ifdef DEBUG_PLAYBACK_QUEUE
		NSLog(@"other error playing video");
#endif
	}
	//TODO: remove the video from playlist
}

- (void)handleDidGetVideoListNotification:(NSNotification *)aNotification {
	// don't do anything for now. when a new video list is saved in MOC. the fetched results controller will call its delegate to handle the data change.
	NSDictionary * userInfo = [aNotification userInfo];
	NSInteger numVideo = [[userInfo objectForKey:@"num_video_added"] integerValue];
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"received video list: %d", numVideo);
#endif
	if ( numVideo == 0 ) {
		// we can't get any new video from the server. try getting by doubling the count
		NSUInteger vidReq = [[userInfo objectForKey:@"num_video_requested"] unsignedIntegerValue];
		if ( vidReq < 41 ) {
			[nowmovTaskController issueGetVideoListForChannel:currentChannel numberOfVideos:vidReq * 2];
		} else {
			// we have finish up this channel
		}
	} else {
		if ( currentIndex + 1 < numberOfVideos )	{
			[self configureControlViewAtIndex:currentIndex + 1];
			// queue the item for play
			[self requestAddVideoAtIndex:currentIndex + 1];
		}
		if ( currentIndex + 2 < numberOfVideos )	{
			[self configureControlViewAtIndex:currentIndex + 2];
			[self requestAddVideoAtIndex:currentIndex + 2];
		}
		if ( !controlScrollView.scrollEnabled ) {
			controlScrollView.scrollEnabled = YES;
			controlScrollView.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
		}
	}
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
	NMControlsView * ctrlView;
	CMTime t;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (movieView.player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				// the instance is ready to play. show time and progress view
				ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
				[ctrlView setControlsHidden:NO animated:YES];
				t = movieView.player.currentItem.asset.duration;
				// check if the time is value
				if ( t.flags & kCMTimeFlags_Valid ) {
					ctrlView.duration = t.value / t.timescale;
					videoDurationInvalid = NO;
				} else {
					videoDurationInvalid = YES;
				}
				break;
			}
			default:
				firstShowControlView = NO;
				break;
		}
	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
		// never change currentIndex here!!
#ifdef DEBUG_PLAYBACK_QUEUE
		NSLog(@"current item changed. t: %d c: %d", numberOfVideos, currentIndex);
#endif
		// ====== video queuing ======
		[self playerQueueVideos];
		// get more video from Nowmov server
		if ( numberOfVideos - currentIndex < 4 ) {
#ifdef DEBUG_PLAYBACK_QUEUE
			NSLog(@"fetch video list for this channel");
#endif
			[nowmovTaskController issueGetVideoListForChannel:currentChannel];
		}
		// ====== update interface ======
		// update the time
		ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
		[UIView beginAnimations:nil context:nil];
		[ctrlView setControlsHidden:NO animated:NO];
		movieView.alpha = 1.0;
		[UIView commitAnimations];
		t = movieView.player.currentItem.asset.duration;
		// check if the time is valid
		if ( t.flags & kCMTimeFlags_Valid ) {
			ctrlView.duration = t.value / t.timescale;
			videoDurationInvalid = NO;
		} else {
			videoDurationInvalid = YES;
		}
		if ( didPlayToEnd ) {
			controlScrollView.scrollEnabled = YES;
		}
	} /*else if ( c == NM_PLAYBACK_BUFFER_EMPTY_CONTEXT) {
		bufferEmpty = [[object valueForKeyPath:keyPath] boolValue];
	} else if ( c == NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT ) {
		NSLog(@"%@ %@", keyPath, [object valueForKeyPath:keyPath]);
	} else if ( c == NM_LOADED_TIME_RANGES_CONTEXT ) {
		if ( movieView.player.rate == 0.0 && bufferEmpty ) {
			NSValue * theVal = [[object valueForKeyPath:keyPath] objectAtIndex:0];
			if ( 
			// check if we should continue playback
			if ( [[object valueForKeyPath:@"currentItem.playbackLikelyToKeepUp"] boolValue] ) {
				[self playVideo];
			}
			
		}
		NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
		if ( !ctrlView.controlsHidden ) {
			// progress bar should show the buffering progress
			NSValue * theVal = [[object valueForKeyPath:keyPath] objectAtIndex:0];
			ctrlView.timeRangeBuffered = [theVal CMTimeRangeValue];
		}
	} */else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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

//- (void)updateControlsForVideoAtIndex:(NSUInteger)idx {
//	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
////	channelNameLabel.text = [currentChannel.channel_name capitalizedString];
////	videoTitleLabel.text = [vid.title uppercaseString];
//	CMTime t = movieView.player.currentItem.asset.duration;
//	// check if the time is value
//	if ( t.flags & kCMTimeFlags_Valid ) {
//		NSInteger sec = t.value / t.timescale;
//		totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
//	} else {
//		videoDurationInvalid = YES;
//	}
//}
//
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

- (void)handleMovieViewPinched:(id)sender {
	UIPinchGestureRecognizer * rcr = (UIPinchGestureRecognizer *)sender;
	if ( rcr.velocity < -2.0 && rcr.scale < 0.6 ) {
		// quit this view
		[self backToChannelView:sender];
	}
//	CGRect theFrame;
//	CGSize theSize;
//	if ( rcr.velocity > 0 && rcr.scale > 1.2 && isAspectFill ) {
//		// scale the player layer down
//		isAspectFill = NO;
//		theFrame = movieView.bounds;
//		// calculate the size
//		theSize = movieView.player.currentItem.presentationSize;
//		theSize.width = floorf(768.0 / theSize.height * theSize.width);
//		theSize.height = 768.0;
//		theFrame.size = theSize;
//		movieView.bounds = theFrame;
//	} else if ( rcr.velocity < 0 && rcr.scale < 0.8 && !isAspectFill ) {
//		isAspectFill = YES;
//		// restore the original size
//		theFrame = self.view.bounds;
//		movieView.bounds = theFrame;
//	}
}

- (IBAction)backToChannelView:(id)sender {
	[movieView.player pause];
	// release the player object, a new AVQueuePlayer object will be created with preparePlayer method is called
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)vote:(id)sender {
	UIView * v = (UIView *)sender;
	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
	if ( v.tag == 1017 ) {
		// vote up
		[nowmovTaskController issueSendUpVoteEventForVideo:[self.fetchedResultsController objectAtIndexPath:self.currentIndexPath] duration:ctrlView.duration elapsedSeconds:ctrlView.timeElapsed];
	} else {
		// vote down
		[nowmovTaskController issueSendDownVoteEventForVideo:[self.fetchedResultsController objectAtIndexPath:self.currentIndexPath] duration:ctrlView.duration elapsedSeconds:ctrlView.timeElapsed];
	}
}

- (IBAction)skipCurrentVideo:(id)sender {
	UIView * btn = (UIView *)sender;
	if ( btn.tag == 1000 ) {
		// prev
	} else {
		// next
		[self showNextVideo:NO];
		// buffer the next next video
//		[self requestAddVideoAtIndex:currentIndex + 2];
//		if ( currentIndex < numberOfVideos ) {
//			currentIndex++;
//		}
//		[movieView.player advanceToNextItem];
	}
}

- (IBAction)showSharePopover:(id)sender {
	
	UIButton * btn = (UIButton *)sender;
	
	SocialSignInViewController * socialCtrl = [[SocialSignInViewController alloc] initWithNibName:@"SocialSignInView" bundle:nil];
	socialCtrl.videoViewController = self;
	
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:socialCtrl];
	
	UIPopoverController * popCtrl = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	popCtrl.popoverContentSize = CGSizeMake(320.0f, 178.0f);
	popCtrl.delegate = self;
	
	[popCtrl presentPopoverFromRect:btn.frame inView:btn.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	
	[socialCtrl release];
	[navCtrl release];
}

- (void)movieViewTouchUp:(id)sender {
	UIView * v = (UIView *)[controlViewArray objectAtIndex:RRIndex(currentIndex)];
	// show the control view
	[UIView beginAnimations:nil context:nil];
	v.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)controlsViewTouchUp:(id)sender {
	UIView * v = (UIView *)sender;
	// hide the control view
	[UIView beginAnimations:nil context:nil];
	v.alpha = 0.0;
	[UIView commitAnimations];
}

#pragma mark Scroll View Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	beginDraggingContentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	movieView.alpha = (1024.0 - scrollView.contentOffset.x + beginDraggingContentOffset.x) / 1024.0;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self stopVideo];
//	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// switch to the next/prev video
	NSUInteger curIdx = (NSUInteger)(scrollView.contentOffset.x / scrollView.bounds.size.width);
	if ( curIdx > currentIndex ) {
		// moved to next video
		[self translateMovieViewByOffset:1.0f];
		firstShowControlView = YES;
		currentIndex++;		// update the currentIndex before calling advanceToNextItem
		[movieView.player advanceToNextItem];
		[movieView.player play];
		if ( currentIndex + 2 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 2];
		}
//		NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
	} else {
		[self playVideo];
		//[self translateMovieViewByOffset:-1.0f];
	}
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
	
	// set predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error == 0", currentChannel]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:5];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_fetch_timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
	[timestampDesc release];
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
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//	NSLog(@"type %d, indexPath %d, %d newIndexPath %d, %d", type, indexPath.row, indexPath.section, newIndexPath.row, newIndexPath.section);
//#endif
	switch (type) {
		case NSFetchedResultsChangeUpdate:
			rowCountHasChanged = NO;
			break;
		case NSFetchedResultsChangeMove:
			rowCountHasChanged = NO;
			NMVideo * vid = (NMVideo *)anObject;
			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			// check if the new position makes the video become ready to be queued
			if ( currentIndex + 2 >= newIndexPath.row ) {
				[self configureControlViewAtIndex:newIndexPath.row];
				[self requestAddVideoAtIndex:newIndexPath.row];
			}
			break;
		default:
		{
			rowCountHasChanged = YES;
			NMVideo * vid = (NMVideo *)anObject;
			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			break;
		}
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//	if ( rowCountHasChanged ) {
//		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
//		NSUInteger prevCount = numberOfVideos;
//		numberOfVideos = [sectionInfo numberOfObjects];
//		if ( numberOfVideos != prevCount ) {
//			UIScrollView * s = (UIScrollView *)self.view;
//			s.scrollEnabled = YES;
//			s.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
//		}
//		rowCountHasChanged = NO;
//	}
	if ( rowCountHasChanged ) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
		numberOfVideos = [sectionInfo numberOfObjects];
		controlScrollView.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
		NSLog(@"controllerDidChangeContent: %d", numberOfVideos);
	}
	if ( freshStart ) {
		if ( numberOfVideos == 0 ) {
			return;
		}
		
		// launching the app with empty video list.
		[nowmovTaskController issueGetVideoListForChannel:currentChannel];
		// now, get the direct url for some videos
		[self requestAddVideoAtIndex:currentIndex];
		// purposely don't queue fetch direct URL for other video in the list to avoid too much network traffic. Delay this till the video starts playing
		freshStart = NO;
//		isReloadWithData = YES;
		[self configureControlViewAtIndex:currentIndex];
	} /*else if ( isReloadWithData ) {
//		isReloadWithData = NO;
		NSUInteger prevCount = numberOfVideos;
		numberOfVideos = [sectionInfo numberOfObjects];
		// check if we has new "near" video added
		if ( currentIndex + 1 >= prevCount && currentIndex + 1 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 1];
			// queue the item for play
			[self requestAddVideoAtIndex:currentIndex + 1];
		}
		if ( currentIndex + 2 >= prevCount && currentIndex + 2 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 2];
			[self requestAddVideoAtIndex:currentIndex + 2];
		}
		if ( numberOfVideos != prevCount ) {
			UIScrollView * s = (UIScrollView *)self.view;
			s.scrollEnabled = YES;
			s.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
		}
	}*/
}

#pragma mark NSIndexPath cache
- (NSIndexPath *)indexPathAtIndex:(NSUInteger)idx {
	// cache recent NM_MAX_VIDEO_IN_QUEUE + 1 index
	NSIndexPath * idxPath = indexPathCache[idx % NM_INDEX_PATH_CACHE_SIZE];
	if ( idxPath == nil ) {
		// create the path
		idxPath = [NSIndexPath indexPathForRow:idx inSection:0];
		indexPathCache[idx % NM_INDEX_PATH_CACHE_SIZE] = [idxPath retain];
	} else if ( idxPath.row != idx ) {
		// remove the old one
		[indexPathCache[idx % NM_INDEX_PATH_CACHE_SIZE] release];
		// put the new one in cache
		idxPath = [NSIndexPath indexPathForRow:idx inSection:0];
		indexPathCache[idx % NM_INDEX_PATH_CACHE_SIZE] = [idxPath retain];
	}
	return idxPath;
}

- (void)freeIndexPathCache {
	for ( NSInteger i = 0; i < NM_INDEX_PATH_CACHE_SIZE; i++ ) {
		[indexPathCache[i] release];
	}
	CFAllocatorDeallocate(NULL, indexPathCache);
}

@end
