//
//  NMUserSettingsTask.m
//  ipad
//
//  Created by Bill So on 10/28/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMUserSettingsTask.h"

NSString * const NMWillEditUserSettingsNotification = @"NMWillEditUserSettingsNotification";
NSString * const NMDidEditUserSettingsNotification = @"NMDidEditUserSettingsNotification";
NSString * const NMDidFailEditUserSettingsNotification = @"NMDidFailEditUserSettingsNotification";

@implementation NMUserSettingsTask
@synthesize settingsDictionary;

- (id)init {
	self = [super init];
	command = NMCommandEditUserSettings;
	// get the setting from NSUserDefaults
	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
	self.settingsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[def objectForKey:NM_SETTING_TWITTER_AUTO_POST_KEY], @"post_to_twitter", 
							   [def objectForKey:NM_SETTING_FACEBOOK_AUTO_POST_KEY], @"post_to_facebook", nil];
	return self;
}

- (void)dealloc {
	[settingsDictionary release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/users/%d/settings?settings[post_to_twitter]=%@&settings[post_to_facebook]=%@", NM_BASE_URL, NM_USER_ACCOUNT_ID, [[settingsDictionary objectForKey:@"post_to_twitter"] boolValue] ? @"true" : @"false", [[settingsDictionary objectForKey:@"post_to_facebook"] boolValue] ? @"true" : @"false"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"PUT"];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif	
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	self.settingsDictionary = [buffer objectFromJSONData];
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:[[settingsDictionary objectForKey:@"post_to_facebook"] boolValue] forKey:NM_SETTING_FACEBOOK_AUTO_POST_KEY];
	[userDefaults setBool:[[settingsDictionary objectForKey:@"post_to_twitter"] boolValue] forKey:NM_SETTING_TWITTER_AUTO_POST_KEY];
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillEditUserSettingsNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidEditUserSettingsNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailEditUserSettingsNotification;
}

@end
