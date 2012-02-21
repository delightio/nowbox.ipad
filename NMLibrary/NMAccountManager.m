//
//  NMAccountManager.m
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMAccountManager.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMPersonProfile.h"
#import "NMChannel.h"

static NMAccountManager * _sharedAccountManager = nil;

@implementation NMAccountManager
@synthesize userDefaults = _userDefaults;
@synthesize facebook = _facebook;
@synthesize facebookAccountStatus = _facebookAccountStatus;
@synthesize twitterAccountStatus = _twitterAccountStatus;

@synthesize socialChannelParsingTimer = _socialChannelParsingTimer, videoImportTimer = _videoImportTimer;

+ (NMAccountManager *)sharedAccountManager {
	if ( _sharedAccountManager == nil ) {
		_sharedAccountManager = [[NMAccountManager alloc] init];
	}
	return _sharedAccountManager;
}

- (id)init {
	self = [super init];
	self.userDefaults = [NSUserDefaults standardUserDefaults];
	// listen to profile notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	// facebook
	[nc addObserver:self selector:@selector(handleDidGetPersonProfile:) name:NMDidGetFacebookProfileNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailGetPersonProfile:) name:NMDidFailGetFacebookProfileNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidParseFeedNotification:) name:NMDidParseFacebookFeedNotification object:nil];
	// twitter
	[nc addObserver:self selector:@selector(handleDidGetPersonProfile:) name:NMDidGetTwitterProfileNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailGetPersonProfile:) name:NMDidFailGetTwitterProfileNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidParseFeedNotification:) name:NMDidParseTwitterFeedNotification object:nil];
	
	// update facebook sync status
	NMDataController * ctrl = [[NMTaskQueueController sharedTaskQueueController] dataController];
	if ( [ctrl myFacebookProfile] ) {
		self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
	} else {
		self.facebookAccountStatus = (NSNumber *)kCFBooleanFalse;
	}
	return self;
}

- (void)dealloc {
	[_facebook release];
	[_userDefaults release];
	[_facebookAccountStatus release];
	[_twitterAccountStatus release];
	if ( _socialChannelParsingTimer ) {
		[_socialChannelParsingTimer invalidate], [_socialChannelParsingTimer release];
	}
	if ( _videoImportTimer ) {
		[_videoImportTimer invalidate], [_videoImportTimer release];
	}
	[super dealloc];
}

#pragma mark Application life-cycle
- (void)applicationDidLaunch {
	[[NMAccountManager sharedAccountManager].facebook extendAccessTokenIfNeeded];
	[self scheduleImportVideos];
	[self scheduleSyncSocialChannels];
}

- (void)applicationDidSuspend {
	if ( _videoImportTimer ) {
		[_videoImportTimer invalidate], self.videoImportTimer = nil;
	}
	if ( _socialChannelParsingTimer ) {
		[_socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
	}
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	// stop all sync related timer invocation
	[tqc stopPollingServer];
	// cancel tasks
//	[tqc cancelAllTasks];
	// cancelling all tasks can cause problem when the app resumes. Say, if we are trying to resolve the vidoe, when canceling the resolution task, we should make reset the status variable of the NMVideo object so that the backend knows how to resolve them again.
}

#pragma mark Twitter

- (void)subscribeAccount:(ACAccount *)acObj {
	NMDataController * ctrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	// create the person profile from the account object
	BOOL isNew;
	NMPersonProfile * theProfile = [ctrl insertNewPersonProfileWithAccountIdentifier:acObj.identifier isNew:&isNew];
	theProfile.nm_account_identifier = acObj.identifier;
	theProfile.nm_me = (NSNumber *)kCFBooleanTrue;
	theProfile.username = acObj.username;
	theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
	theProfile.nm_error = [NSNumber numberWithInteger:NMErrorPendingImport];
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];	
	// issue call to get user info
	[tqc issueGetProfile:theProfile account:acObj];
}

#pragma mark Facebook

- (Facebook *)facebook {
	if ( _facebook == nil ) {
		_facebook = [[Facebook alloc] initWithAppId:@"190577807707530" andDelegate:self];
		if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY] 
			&& [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY]) {
			_facebook.accessToken = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
			_facebook.expirationDate = [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
		}
	}
	return _facebook;
}

- (BOOL)facebookAuthorized {
	NSString * tk = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	if ( tk && ![tk isEqualToString:@""] ) {
		return YES;
	}
	return NO;
}

- (void)authorizeFacebook {
	NSArray *permissions = [NSArray arrayWithObjects:@"publish_stream", @"read_stream", nil];
	[self.facebook authorize:permissions];
}

- (void)signOutFacebookOnCompleteTarget:(id)aTarget action:(SEL)completionSelector {
	signOutAction = completionSelector;
	signOutTarget = aTarget;
	dispatch_async(dispatch_get_main_queue(), ^{
		// stop sync timer
		if ( _videoImportTimer ) {
			[_videoImportTimer invalidate], self.videoImportTimer = nil;
		}
		if ( _socialChannelParsingTimer ) {
			[_socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
		}
		// cancel all existing Facebook related tasks
		NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
		[tqc prepareSignOutFacebook];
		// make sure the backend will not queue any facebook tasks from now on.
		// remove the data as well
		double delayInSeconds = 2.0;	// chill for 2 sec. hopefully all the tasks are cancelled by then.
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[tqc dataController] deleteFacebookCacheForLogout];
			if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY]) {
				[_userDefaults removeObjectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
				[_userDefaults removeObjectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
				[_userDefaults synchronize];
				[_userDefaults setObject:(NSNumber *)kCFBooleanFalse forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
				NM_USER_FACEBOOK_CHANNEL_ID = 0;
			}
			// on-completion, begin sign out
			[self.facebook logout];
			[tqc endSignOutFacebook];
		});
	});
}

#pragma mark Facebook delegate methods

- (void)fbDidLogin {
	// save the token
	[_userDefaults setObject:[_facebook accessToken] forKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	[_userDefaults setObject:[_facebook expirationDate] forKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
	[_userDefaults synchronize];
	
	// issue call to get user info
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	BOOL isNew;
	NMPersonProfile * thePerson = [tqc.dataController insertMyNewEmptyFacebookProfile:&isNew];
	[[NMTaskQueueController sharedTaskQueueController] issueGetProfile:thePerson account:nil];
	// Login interface should listen to notification so that it can update the interface accordingly
	self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncPendingInitialSync];
}

- (void)fbDidLogout {
    // Remove saved authorization information if it exists
	[signOutTarget performSelector:signOutAction withObject:nil];
	[_facebook release], _facebook = nil;
	self.facebookAccountStatus = (NSNumber *)kCFBooleanFalse;
}

- (void)fbDidExtendToken:(NSString*)accessToken expiresAt:(NSDate*)expiresAt {
    [_userDefaults setObject:accessToken forKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
    [_userDefaults setObject:expiresAt forKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
    [_userDefaults synchronize];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	
}

- (void)fbSessionInvalidated {
	_facebook.accessToken = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	_facebook.expirationDate = [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
	[_facebook extendAccessToken];
}

#pragma mark Sync notification handlers
- (void)handleDidGetPersonProfile:(NSNotification *)aNotification {
	/*
	 Listen to this notificaiton only when the user signs in Twitter or Facebook.
	 
	 For Facebook, we set this task queue schedule to listen to notification in the NMAccountManager. When user has successfully granted this app access to his/her Facebook account, NMAccountManager will get called (the facebook delegate)
	 */
	NMPersonProfile * theProfile = [[aNotification userInfo] objectForKey:@"target_object"];
	if ( [theProfile.nm_me boolValue] ) {
		// trigger feed parsing
		[self scheduleSyncSocialChannels];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:[aNotification name] object:nil];
	}
}

- (void)handleDidFailGetPersonProfile:(NSNotification *)aNotificaton {
	// fail to sync
	NMPersonProfile * theProfile = [[aNotificaton userInfo] objectForKey:@"target_object"];
	if ( [[aNotificaton name] isEqualToString:NMDidFailGetFacebookProfileNotification] && [theProfile.nm_me boolValue] ) {
		// fail to sync my facebook account. try grab the profile again after 2.0
		[self performSelector:@selector(scheduleImportVideos) withObject:nil afterDelay:2.0];
		// scheduleImportVideos checks for person profile to update too. This is what we need.
	}
}

- (void)handleDidParseFeedNotification:(NSNotification *)aNotification {
	NSDictionary * infoDict = [aNotification userInfo];
	NSInteger c = [[infoDict objectForKey:@"num_video_added"] integerValue];
	if ( c ) {
		// we found new video in the news feed
		[self scheduleImportVideos];
		numberOfVideosAddedFromFacebook += c;
	}
	NMChannel * chnObj = [infoDict objectForKey:@"channel"];
	switch ([chnObj.type integerValue]) {
		case NMChannelUserTwitterType:
		{
			[[NMTaskQueueController sharedTaskQueueController] issueProcessFeedWithTwitterInfo:infoDict];
			break;
		}
		case NMChannelUserFacebookType:
		{
			NSString * urlStr = [infoDict objectForKey:@"next_url"];
			if ( urlStr ) {
				[[NMTaskQueueController sharedTaskQueueController] issueProcessFeedForFacebookChannel:chnObj directURLString:urlStr];
			} else if ( numberOfVideosAddedFromFacebook == 0 ) {
				self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
			}
			break;
		}	
		default:
			break;
	}
}

#pragma mark Sync methods
- (void)scheduleSyncSocialChannels {
	if ( [self.facebookAccountStatus integerValue] == 0 ) return;
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"scheduleSyncSocialChannels");
#endif
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	// get the qualified channels
	NSArray * theChannels = [tqc.dataController socialChannelsForSync];
	NSUInteger c = [theChannels count];
	for (NSUInteger i = 0; (i < c && i < 5); i++) {
		[tqc issueProcessFeedForChannel:[theChannels objectAtIndex:i]];
	}
	if ( c > 5 && _socialChannelParsingTimer == nil ) {
		// schedule a timer task to process other channels
		self.socialChannelParsingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scheduleSyncSocialChannels) userInfo:nil repeats:YES];
	} else if ( _socialChannelParsingTimer ) {
		[_socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
	}
	// reset the value
	numberOfVideosAddedFromFacebook = 0;
}

- (void)scheduleImportVideos {
	if ( [self.facebookAccountStatus integerValue] == 0 ) return;
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"scheduleImportVideos");
#endif
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	// get the qualified videos
	NSArray * theProfiles = [tqc.dataController personProfilesForSync:2];
	NSInteger cnt = 4;
	if ( theProfiles ) cnt = 2;
	NSArray * theVideos = [tqc.dataController videosForSync:cnt];
	
	if ( theVideos == nil && theProfiles == nil ) {
		// stop the timer task
		if ( _videoImportTimer ) {
			[_videoImportTimer invalidate];
			self.videoImportTimer = nil;
#ifdef DEBUG_FACEBOOK_IMPORT
			NSLog(@"stop video import timer");
#endif
		}
#ifdef DEBUG_FACEBOOK_IMPORT
		NSLog(@"no more video or profiles to import");
#endif
		self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
		// return immediately if no video
		return;
	}
	self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncSyncInProgress];
	for (NMConcreteVideo * vdo in theVideos) {
		[tqc issueImportVideo:vdo];
	}
	for (NMPersonProfile * pfo in theProfiles) {
		[tqc issueGetProfile:pfo account:nil];
	}
	if ( _videoImportTimer == nil ) self.videoImportTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scheduleImportVideos) userInfo:nil repeats:YES];
}


@end
