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
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

static NMAccountManager * _sharedAccountManager = nil;
static NSString * const NMFacebookAppID = @"220704664661437";
static NSString * const NMFacebookAppSecret = @"da9f5422fba3f8caf554d6bd927dc430";

@implementation NMAccountManager
@synthesize userDefaults = _userDefaults;
@synthesize facebook = _facebook;
@synthesize facebookAccountStatus = _facebookAccountStatus;
@synthesize twitterAccountStatus = _twitterAccountStatus;
@synthesize updatedChannels = _updatedChannels;
@synthesize accountStore = _accountStore;
@synthesize currentTwitterAccount = _currentTwitterAccount;
@synthesize twitterProfile = _twitterProfile;
@synthesize facebookProfile = _facebookProfile;

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
	// listen to import notification, we only care about successful import
	[nc addObserver:self selector:@selector(handleDidImportYoutubeVideoNotification:) name:NMDidImportYouTubeVideoNotification object:nil];
	
	// update facebook sync status
	NMDataController * ctrl = [[NMTaskQueueController sharedTaskQueueController] dataController];
	if ( [ctrl myFacebookProfile] ) {
		self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
	} else {
		self.facebookAccountStatus = (NSNumber *)kCFBooleanFalse;
	}
	if ( [ctrl myTwitterProfile] ) {
		self.twitterAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
	} else {
		self.twitterAccountStatus = (NSNumber *)kCFBooleanFalse;
	}
	return self;
}

- (void)dealloc {
	[_twitterProfile release];
	[_facebookProfile release];
	[_facebook release];
	[_userDefaults release];
	[_accountStore release];
	[_currentTwitterAccount release];
	[_facebookAccountStatus release];
	[_twitterAccountStatus release];
	[_updatedChannels release];
	if ( _socialChannelParsingTimer ) {
		[_socialChannelParsingTimer invalidate], [_socialChannelParsingTimer release];
	}
	if ( _videoImportTimer ) {
		[_videoImportTimer invalidate], [_videoImportTimer release];
	}
	[super dealloc];
}

- (NSMutableSet *)updatedChannels {
	if ( _updatedChannels == nil ) {
		self.updatedChannels = [NSMutableSet setWithCapacity:2];
	}
	return _updatedChannels;
}

- (void)setFacebookAccountStatus:(NSNumber *)aStatus {
	if ( _facebookAccountStatus == aStatus ) return;
	
	[_facebookAccountStatus release], _facebookAccountStatus = nil;
	if ( aStatus ) {
		_facebookAccountStatus = [aStatus retain];
		if ( [_facebookAccountStatus integerValue] == NMSyncAccountActive && numberOfVideoImported ) {
			// send notification for every channel
			NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
			for (NMChannel * chnObj in _updatedChannels) {
				// arbitrarily fill in 1 as value
				[nc postNotificationName:NMDidGetChannelVideoListNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:1], @"num_video_added", [NSNumber numberWithUnsignedInteger:1], @"num_video_received", [NSNumber numberWithUnsignedInteger:1], @"num_video_requested", chnObj, @"channel", nil]];
			}
			// reset value
			numberOfVideoImported = 0;
			self.updatedChannels = nil;
		}
	}
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

- (NMPersonProfile *)twitterProfile {
	if ( [self.twitterAccountStatus integerValue] == 0 ) return nil;
	if ( _twitterProfile == nil ) {
		_twitterProfile = [[[[NMTaskQueueController sharedTaskQueueController] dataController] myTwitterProfile] retain];
	}
	return _twitterProfile;
}

- (void)checkAndPushTwitterAccountOnGranted:(void (^)(void))grantBlock {
	// use built-in twitter integration
	// Create an account store object.
	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
	
	// Create an account type that ensures Twitter accounts are retrieved.
	ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	// Request access from the user to use their Twitter accounts.
	[accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
		if(granted) {
			if ( [TWTweetComposeViewController canSendTweet] ) {
				// pass the account store to Social Login Controller
				dispatch_async(dispatch_get_main_queue(), grantBlock);
			} else {
				// We don't have right to access Twitter account. Send user to the Settings app
				dispatch_async(dispatch_get_main_queue(), ^{
					UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil message:@"You have not yet signed in Twitter.\nDo you want to do it now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Settings", nil];
					[alertView show];
					[alertView release];
				});
			}
		} else {
			//			// unhighlight the cell
			//			dispatch_async(dispatch_get_main_queue(), ^{
			//				[tableView deselectRowAtIndexPath:indexPath animated:YES];
			//			});
		}
	}];
	[accountStore release];
}

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
	// update twitter account status
	self.twitterAccountStatus = [NSNumber numberWithInteger:NMSyncPendingInitialSync];
	
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];	
	// issue call to get user info
	[tqc issueGetProfile:theProfile account:acObj];
}

- (ACAccountStore *)accountStore {
	if ( _accountStore == nil ) {
		_accountStore = [[ACAccountStore alloc] init];
	}
	return _accountStore;
}

- (ACAccount *)currentTwitterAccount {
	if ( _currentTwitterAccount == nil ) {
		// grab the account object
		NMPersonProfile * thePerson = [[[NMTaskQueueController sharedTaskQueueController] dataController] myTwitterProfile];
		if ( thePerson ) {
			_currentTwitterAccount = [[self.accountStore accountWithIdentifier:thePerson.nm_account_identifier] retain];
		}
	}
	return _currentTwitterAccount;
}

- (void)signOutTwitterOnCompleteTarget:(id)aTarget action:(SEL)completionSelector {
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
		// cancel all existing Twitter related tasks
		NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
		[tqc prepareSignOutTwitter];
		// make sure the backend will not queue any facebook tasks from now on.
		// remove the data as well
		double delayInSeconds = 2.0;	// chill for 2 sec. hopefully all the tasks are cancelled by then.
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[tqc dataController] deleteCacheForSignOut:NMChannelUserTwitterType];
			NM_USER_TWITTER_CHANNEL_ID = 0;
			self.twitterAccountStatus = (NSNumber *)kCFBooleanFalse;
			self.twitterProfile = nil;
			// on-completion, begin sign out
			[tqc endSignOutTwitter];
		});
	});
}

#pragma mark Facebook

- (NMPersonProfile *)facebookProfile {
	if ( [self.facebookAccountStatus integerValue] == 0 ) return nil;
	if ( _facebookProfile == nil ) {
		_facebookProfile = [[[[NMTaskQueueController sharedTaskQueueController] dataController] myFacebookProfile] retain];
	}
	return _facebookProfile;
}

- (Facebook *)facebook {
	if ( _facebook == nil ) {
		_facebook = [[Facebook alloc] initWithAppId:NMFacebookAppID andDelegate:self];
		_facebook.appSecret = NMFacebookAppSecret;
		if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY] 
			&& [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY]) {
			_facebook.accessToken = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
			_facebook.expirationDate = [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
		}
	}
	return _facebook;
}

- (void)authorizeFacebook {
	NSArray *permissions = [NSArray arrayWithObjects:@"publish_stream", @"read_stream", @"publish_actions", nil];
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
			[[tqc dataController] deleteCacheForSignOut:NMChannelUserFacebookType];
			if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY]) {
				[_userDefaults removeObjectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
				[_userDefaults removeObjectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
				[_userDefaults synchronize];
				[_userDefaults setObject:(NSNumber *)kCFBooleanFalse forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
				NM_USER_FACEBOOK_CHANNEL_ID = 0;
			}
			self.facebookAccountStatus = (NSNumber *)kCFBooleanFalse;
			self.facebookProfile = nil;
			// on-completion, begin sign out
			[self.facebook logout];
			[tqc endSignOutFacebook];
		});
	});
}

#pragma mark Facebook delegate methods

- (void)fbDidLogin {
	// save the token
	NSLog(@"expration date: %@", [_facebook expirationDate]);
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
		if ( [theProfile.nm_type integerValue] == NMChannelUserFacebookType ) {
			// we should extend the token
			[_facebook extendAccessTokenIfNeeded];
		}
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
	}
	NMChannel * chnObj = [infoDict objectForKey:@"channel"];
	switch ([chnObj.type integerValue]) {
		case NMChannelUserTwitterType:
		{
			// We are getting the user's first 100 tweets now. Probably don't need to iteratively crawl user's complete tweet history.
//			[[NMTaskQueueController sharedTaskQueueController] issueProcessFeedWithTwitterInfo:infoDict];
			break;
		}
		case NMChannelUserFacebookType:
		{
			NSString * urlStr = [infoDict objectForKey:@"next_url"];
			if ( urlStr ) {
				[[NMTaskQueueController sharedTaskQueueController] issueProcessFeedForFacebookChannel:chnObj directURLString:urlStr];
			}
			break;
		}	
		default:
			break;
	}
}

- (void)handleDidImportYoutubeVideoNotification:(NSNotification *)aNotification {
	numberOfVideoImported++;
	NMConcreteVideo * conVdo = [[aNotification userInfo] objectForKey:@"target_object"];
	NSSet * vdoSet = conVdo.channels;
	for (NMVideo * vdoObj in vdoSet) {
		[self.updatedChannels addObject:vdoObj.channel];
	}
}

#pragma mark Sync methods
- (void)scheduleSyncSocialChannels {
#if defined(DEBUG_FACEBOOK_IMPORT) || defined (DEBUG_TWITTER_IMPORT)
	NSLog(@"scheduleSyncSocialChannels");
#endif
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	if ( [self.facebookAccountStatus integerValue] || [self.twitterAccountStatus integerValue] ) {
		// get the qualified channels
		NSArray * theChannels = [tqc.dataController socialChannelsForSync];
		NSUInteger c = [theChannels count];
		BOOL foundFBChn = NO;
		BOOL foundTWChn = NO;
		NSInteger chnType = 0;
		NSInteger idx = 0;
		for (NMChannel * chn in theChannels) {
			[tqc issueProcessFeedForChannel:chn];
			chnType = [chn.type integerValue];
			foundTWChn |= chnType == NMChannelUserTwitterType;
			foundFBChn |= chnType == NMChannelUserFacebookType;
			if ( ++idx == 5 ) {
				break; // queue no more than 5 tasks
			}
		}
		if ( foundFBChn ) {
			self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncSyncInProgress];
		}
		if ( foundTWChn ) {
			self.twitterAccountStatus = [NSNumber numberWithInteger:NMSyncSyncInProgress];
		}
		if ( c > 5 && _socialChannelParsingTimer == nil ) {
			// schedule a timer task to process other channels
			self.socialChannelParsingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scheduleSyncSocialChannels) userInfo:nil repeats:YES];
		} else if ( _socialChannelParsingTimer ) {
			[_socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
			if ( _videoImportTimer == nil ) {
				// if there's no scheduled video import timer as well, it's safe to declare that this round of sync process has been completed
				self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
			}
		}
	}
}

- (void)scheduleImportVideos {
	if ( [self.facebookAccountStatus integerValue] == 0 && [self.twitterAccountStatus integerValue] == 0 ) return;
#if defined(DEBUG_FACEBOOK_IMPORT) || defined (DEBUG_TWITTER_IMPORT)
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
		// check if there's scheduled channel sync timer
		if ( _socialChannelParsingTimer == nil ) {
			// if there's no scheduled video import timer as well, it's safe to declare that this round of sync process has been completed
			if ( [_facebookAccountStatus integerValue] ) self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
			if ( [_twitterAccountStatus integerValue] ) self.twitterAccountStatus = [NSNumber numberWithInteger:NMSyncAccountActive];
		}
		// return immediately if no video
		return;
	}
	if ( [_facebookAccountStatus integerValue] ) self.facebookAccountStatus = [NSNumber numberWithInteger:NMSyncSyncInProgress];
	if ( [_twitterAccountStatus integerValue] ) self.twitterAccountStatus = [NSNumber numberWithInteger:NMSyncSyncInProgress];
	for (NMConcreteVideo * vdo in theVideos) {
		[tqc issueImportVideo:vdo];
	}
	for (NMPersonProfile * pfo in theProfiles) {
		[tqc issueGetProfile:pfo account:nil];
	}
	if ( _videoImportTimer == nil ) self.videoImportTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(scheduleImportVideos) userInfo:nil repeats:YES];
}


@end
