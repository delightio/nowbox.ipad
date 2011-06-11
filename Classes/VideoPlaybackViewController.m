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
#import "NMAVQueuePlayer.h"
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


#define RRIndex(idx) idx % 4

@interface VideoPlaybackViewController (PrivateMethods)

//- (void)insertVideoAtIndex:(NSUInteger)idx;
//- (void)queueVideoToPlayer:(NMVideo *)vid;
- (void)playerQueueVideos;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewAtIndex:(NSInteger)idx;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)translateMovieViewByOffset:(CGFloat)offset;
- (void)playVideo;
- (void)stopVideo;

// index path cache
- (NSIndexPath *)indexPathAtIndex:(NSUInteger)idx;
- (void)freeIndexPathCache;

// debug message
- (void)printDebugMessage:(NSString *)str;

@end


@implementation VideoPlaybackViewController
@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;
@synthesize currentIndexPath=currentIndexPath_;
@synthesize prototypeChannelPanel;
@synthesize prototypeChannelContent;
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
	currentXOffset = 0.0f;
		
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
//	[nc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
//	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
//	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidRefreshChannelVideoListNotification object:nil];
//	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMDidFailGetYouTubeDirectURLNotification object:nil];
//	[nc addObserver:self selector:@selector(handleErrorNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
//	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMURLConnectionErrorNotification object:nil];
	// listen to item finish up playing notificaiton
	[nc addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	// listen to system notification
	[nc addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// setup gesture recognizer
	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewPinched:)];
//	[movieView addGestureRecognizer:pinRcr];
	[controlScrollView addGestureRecognizer:pinRcr];
	[pinRcr release];
	// set target-action methods
	[movieView addTarget:self action:@selector(movieViewTouchUp:)];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self playVideo];
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
	[self setPrototypeChannelPanel:nil];
	[self setPrototypeChannelContent:nil];
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
	[prototypeChannelPanel release];
	[prototypeChannelContent release];
    [super dealloc];
}

#pragma mark Playback data structure

- (NMVideo *)currentVideo {
	return [self.fetchedResultsController objectAtIndexPath:self.currentIndexPath];
}

- (void)setPlaybackCheckpoint {
	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
	CMTime aTime = movieView.player.currentTime;
	if ( aTime.flags & kCMTimeFlags_Valid ) {
		currentChannel.nm_time_elapsed_value = [NSNumber numberWithLongLong:aTime.value];
		currentChannel.nm_time_elapsed_timescale = [NSNumber numberWithInteger:aTime.timescale];
	}
	currentChannel.nm_last_vid = self.currentVideo.vid;
	// send event back to nowmov server
	[nowmovTaskController issueSendViewingEventForVideo:self.currentVideo duration:ctrlView.duration elapsedSeconds:ctrlView.timeElapsed];
}

- (NSIndexPath *)currentIndexPath {
	return [self indexPathAtIndex:currentIndex];
//	if ( currentIndexPath_ == nil ) {
//		currentIndexPath_ = [[self indexPathAtIndex:currentIndex] retain];
//	} else if ( currentIndexPath_.row != currentIndex ) {
//		[currentIndexPath_ release];
//		currentIndexPath_ = [[self indexPathAtIndex:currentIndex] retain];
//	}
//	
//	return currentIndexPath_;
}

- (void)setCurrentChannel:(NMChannel *)chnObj {
	if ( currentChannel ) {
		if ( currentChannel != chnObj ) {
			// clear all task related to the previous channel
			[nowmovTaskController cancelAllPlaybackTasksForChannel:currentChannel];
			[currentChannel release];
			currentChannel = [chnObj retain];
		}
	} else {
		currentChannel = [chnObj retain];
	}
	movieView.player = nil;
	currentIndex = 0;
	currentXOffset = 0.0f;
	firstShowControlView = YES;
	// reset fetch result
	self.fetchedResultsController = nil;
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	numberOfVideos = [sectionInfo numberOfObjects];
	
	// update status variable to point to the last video
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"vid = %@", currentChannel.nm_last_vid]];
	[request setReturnsObjectsAsFaults:NO];
	NSArray * result = [self.managedObjectContext executeFetchRequest:request error:nil];
	if ( result && [result count] ) {
		// we can find the last watched video.
		NSIndexPath * idxPath = [self.fetchedResultsController indexPathForObject:[result objectAtIndex:0]];
		currentIndex = idxPath.row;
		currentXOffset = (CGFloat)(currentIndex * 1024);
	}
	[request release];
	// reset player position
	CGRect theFrame = movieView.frame;
	theFrame.origin.x = currentXOffset;
	movieView.frame = theFrame;
	// show activity indicator
	[movieView setActivityIndicationHidden:NO animated:NO];
	
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
		if ( currentIndex + 1 < numberOfVideos )	{
			[self configureControlViewAtIndex:currentIndex + 1];
			[self requestAddVideoAtIndex:currentIndex + 1];
		}
		if ( currentIndex + 2 < numberOfVideos ) {
			[self configureControlViewAtIndex:currentIndex + 2];
			[self requestAddVideoAtIndex:currentIndex + 2];
		}
		controlScrollView.scrollEnabled = YES;
		// init the drag offset so that when scrollViewDidScroll delegate is called, alpha of movieView will not be set to a weird value
		beginDraggingContentOffset.x = currentXOffset;
		// set offset to the last viewed video place
		controlScrollView.contentSize = CGSizeMake((CGFloat)(numberOfVideos * 1024), 768.0f);
		controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);	// this will trigger delegate method "scrollViewDidScroll"
		
		if ( numberOfVideos < NM_INDEX_PATH_CACHE_SIZE ) {
			[nowmovTaskController issueGetVideoListForChannel:currentChannel];
		}
		//TODO: check if need to queue fetch video list
	} else {
		// there's no video. fetch video right now
		freshStart = YES;
		[nowmovTaskController issueGetVideoListForChannel:currentChannel];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	}
}

#pragma mark Debug message
- (void)printDebugMessage:(NSString *)str {
	debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", str];
	[debugMessageView scrollRangeToVisible:NSMakeRange([debugMessageView.text length], 0)];
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
	NMAVQueuePlayer * player = [[NMAVQueuePlayer alloc] initWithItems:[NSArray arrayWithObject:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:vid.nm_direct_url]]]];
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
				NSInteger d = t.value / t.timescale;
				ctrlView.duration = d;
				// duration of video should never be 0. Do NOT set the flag to YES if duration == 0.
				if ( d ) videoDurationInvalid = NO;
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
			currentXOffset += 1024.0f;
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
	//if ( aEndOfVideo ) {
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
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)showPreviousVideo {
	currentIndex--;
	currentXOffset -= 1024.0f;
	firstShowControlView = YES;
	// scroll to next video
	// translate the movie view
	[controlScrollView setContentOffset:CGPointMake(controlScrollView.contentOffset.x + controlScrollView.bounds.size.width, 0.0f) animated:NO];
	[self translateMovieViewByOffset:1.0f];
	
	[movieView.player revertPreviousItem:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.currentVideo.nm_direct_url]]];
	[movieView.player play];
	
	// update the movie control view
	if ( currentIndex + 2 < numberOfVideos ) {
		[self configureControlViewAtIndex:currentIndex + 2];
	} else {
		// get more video here
	}
	// make the view visible
	[self performSelector:@selector(showPlayerAndControl) withObject:nil afterDelay:0.1];
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
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
			[self performSelectorOnMainThread:@selector(printDebugMessage:) withObject:[NSString stringWithFormat:@"issue resolve direct URL: %@", vid.title] waitUntilDone:NO];
#endif
			vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
			[nowmovTaskController issueGetDirectURLForVideo:vid];
		}
	} else if ( vid.nm_playback_status >= NMVideoQueueStatusDirectURLReady ) {
		if ( idx == currentIndex && movieView.player == nil ) {
			[self preparePlayer];
		} else {
			[self playerQueueVideos];
		}
	}
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
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
						[self performSelectorOnMainThread:@selector(printDebugMessage:) withObject:[NSString stringWithFormat:@"added video to queue player: %@, %@", vid.nm_sort_order, vid.title] waitUntilDone:NO];
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
			} /*else {
				// just check if we should resolve the direct URL
				[self requestAddVideoAtIndex:i];
			}*/
		} else {
			break;
		}
	}
}

#pragma mark NMVideoListUpdateDelegate methods
- (BOOL)task:(NMRefreshChannelVideoListTask *)vidListTask shouldBeginPlaybackSafeUpdateForChannel:(NMChannel *)chnl {
	return chnl == currentChannel;
}

- (NMVideo *)currentVideoForTask:(NMRefreshChannelVideoListTask *)vidListTask {
	return self.currentVideo;
}

- (void)taskBeginPlaybackSafeUpdate:(NMRefreshChannelVideoListTask *)vidListTask {
	controlScrollView.scrollEnabled = NO;
	// cancel Direct Resolution Task and Get Vdieo list task that may have been triggered when the user is waiting for videos
	BOOL firstPass = YES;
	for (AVPlayerItem * pItem in movieView.player.items ) {
		if ( firstPass ) {
			firstPass = NO;
		} else {
			[movieView.player removeItem:pItem];
		}
	}
}

- (void)taskEndPlaybackSafeUpate:(NMRefreshChannelVideoListTask *)vidListTask {
	controlScrollView.scrollEnabled = YES;
}

#pragma mark Notification handling
- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	NMVideo * vid = [[aNotification userInfo] objectForKey:@"target_object"];
	vid.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved: %@", vid.title);
#endif
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	[self performSelectorOnMainThread:@selector(printDebugMessage:) withObject:[NSString stringWithFormat:@"resolved URL: %@", vid.title] waitUntilDone:NO];
#endif
	// check if we should queue the video resolved
	if ( movieView.player == nil ) {
		NSIndexPath * idxPath = [self.fetchedResultsController indexPathForObject:vid];
		if ( currentIndex == idxPath.row )
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
	if ( currentIndex + 1 == numberOfVideos ) {
		// finish up playing the whole channel
		[self dismissModalViewControllerAnimated:YES];
	} else {
		didPlayToEnd = YES;
		[self showNextVideo:YES];
	}
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
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
			debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\ndirect URL resolution failed: %@ %@", [[aNotification userInfo] objectForKey:@"error"], vid.title];
#endif
		}
	} else if ( [[aNotification name] isEqualToString:NMURLConnectionErrorNotification] ) {
		// general network error. 
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
		debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", [[aNotification userInfo] objectForKey:@"message"]];
		NSLog(@"general connection error: %@", [[aNotification userInfo] objectForKey:@"message"]);
#endif
	} else if ( [[aNotification name] isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification] ) {
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
		NSError * theErr = [[aNotification userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey];
		debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", [theErr localizedDescription]];
		NSLog(@"can't finish playing video. just skip it!");
#endif
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
	NSLog(@"movie view position %f %f %f", movieView.frame.origin.x, controlScrollView.contentOffset.x, movieView.alpha);
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
				[movieView setActivityIndicationHidden:YES animated:YES];
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

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)aNotification {
	// resume playing the video
	[self playVideo];
	// send event back to server
	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
	[nowmovTaskController issueSendViewingEventForVideo:self.currentVideo duration:ctrlView.duration elapsedSeconds:ctrlView.timeElapsed];
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
	[self setPlaybackCheckpoint];
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
		if ( currentIndex + 1 == numberOfVideos ) {
			// already playing the last video in the channel
			NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
			[ctrlView showLastVideoMessage];
		} else {
			// next
			[self showNextVideo:NO];
		}
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

- (IBAction)togglePrototypeChannelPanel:(id)sender {
	CGRect theFrame;
	if ( self.prototypeChannelPanel == nil ) {
		// load the view
		[[NSBundle mainBundle] loadNibNamed:@"ChannelPanelView" owner:self options:nil];
		[prototypeChannelScrollView addSubview:self.prototypeChannelContent];
		prototypeChannelScrollView.contentSize = self.prototypeChannelContent.bounds.size;
		theFrame = prototypeChannelPanel.frame;
		theFrame.origin.y = self.view.bounds.size.height;
		prototypeChannelPanel.frame = theFrame;
		[self.view addSubview:self.prototypeChannelPanel];
	}
	theFrame = prototypeChannelPanel.frame;
	BOOL panelHidden = YES;
	if ( theFrame.origin.y < 768.0 ) {
		// assume the panel is visible
		panelHidden = NO;
	}
	[UIView beginAnimations:nil context:nil];
	if ( panelHidden ) {
		movieView.center = CGPointMake(512.0f, 768.0f / 4.0f);
		controlScrollView.center = CGPointMake(512.0f, 768.0f / 4.0f);
		// slide in
		theFrame.origin.y = 384.0f;
		prototypeChannelPanel.frame = theFrame;
		// scale down
		movieView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
		controlScrollView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
	} else {
		movieView.center = CGPointMake(512.0f, 768.0f / 2.0f);
		controlScrollView.center = CGPointMake(512.0f, 768.0f / 2.0f);
		// slide out
		theFrame.origin.y = 768.0;
		prototypeChannelPanel.frame = theFrame;
		// scale up
		movieView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
		controlScrollView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
	}
	[UIView commitAnimations];
	// slide in/out the prototype channel panel
	// scale down movie control
	// scale playback view
	// slide in/out channel panel
}

- (IBAction)refreshVideoList:(id)sender {
	[nowmovTaskController issueRefreshVideoListForChannel:currentChannel delegate:self];
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
	if ( scrollView.contentOffset.x < currentXOffset ) {
		[scrollView setContentOffset:CGPointMake(currentXOffset, 0.0) animated:NO];
	} else {
		movieView.alpha = (1024.0 - scrollView.contentOffset.x + beginDraggingContentOffset.x) / 1024.0;
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self stopVideo];
	// this is for preventing user from flicking continuous. user has to flick through video one by one. scrolling will enable again in "scrollViewDidEndDecelerating"
	scrollView.scrollEnabled = NO;
//	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// switch to the next/prev video
	scrollView.scrollEnabled = YES;
	if ( scrollView.contentOffset.x > currentXOffset ) {
		// moved to next video
		[self translateMovieViewByOffset:1.0f];
		firstShowControlView = YES;
		CGFloat offsetDiff = scrollView.contentOffset.x - currentXOffset;
		if ( offsetDiff > 1024.0f ) {
			NSInteger i = (NSInteger)(offsetDiff / 1024.0f);
			for ( NSInteger j = 0 ; j < i; j++ ) {
				[movieView.player advanceToNextItem];
			}
			[movieView.player play];
			currentIndex += i;
			currentXOffset = scrollView.contentOffset.x;
		} else {
			currentIndex++;		// update the currentIndex before calling advanceToNextItem
			currentXOffset += 1024.0f;
			[movieView.player advanceToNextItem];
			[movieView.player play];
		}
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
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
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
	switch (type) {
		case NSFetchedResultsChangeDelete:
			rowCountHasChanged = YES;
			//MARK: code below seems useless base on findings studying FRCDeleteTest sample code
//			NMVideo * vid = (NMVideo *)anObject;
//			// setting nm_sort_order will trigger another call to the FRC's delegate method
//			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
//			// check if the new position makes the video become ready to be queued
//			if ( currentIndex + 2 >= indexPath.row ) {
//				[self configureControlViewAtIndex:indexPath.row];
//				[self requestAddVideoAtIndex:indexPath.row];
//				if ( currentIndex == 0 && vid.nm_playback_status == NMVideoQueueStatusDirectURLReady && movieView.player == nil ) {
//					// we should start playing the video
//					[self preparePlayer];
//				}
//			}
			break;
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			rowCountHasChanged = NO;
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
