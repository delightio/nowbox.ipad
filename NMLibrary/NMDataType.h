//
//  NMDataType.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

typedef enum {
	NMTaskExecutionStateNew,
	NMTaskExecutionStateWaitingInConnectionQueue,
	NMTaskExecutionStateConnectionActive,
	NMTaskExecutionStateConnectionCompleted,
	NMTaskExecutionStateConnectionFailed,
	NMTaskExecutionStateCanceled,
} NMTaskExecutionState;

typedef enum {
	NMCommandGetAllChannels			= 1,
	NMCommandGetSubscribedChannels,
	NMCommandGetChannelsForCategory,
	NMCommandSearchChannels,
	NMCommandGetChannelWithID,			// this is for subscribing to debug channels
	NMCommandGetFeaturedChannelsForCategories,
	NMCommandPollChannel,
	NMCommandCompareSubscribedChannels,
	NMCommandGetChannelDetail,
	NMCommandCreateKeywordChannel,
	NMCommandCreateUser,
	NMCommandVerifyFacebookUser,
	NMCommandVerifyTwitterUser,
	NMCommandVerifyYouTubeUser,
	NMCommandDeauthorizeYoutubeUser,
	NMCommandEditUserSettings,
	NMCommandUserSynchronize,
	NMCommandGetToken,
	NMCommandPollUser,
	NMCommandSendEvent,
	NMCommandGetFeaturedCategories,
	NMCommandGetMoreVideoForChannel,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetYouTubeDirectURLAndInfo,
	NMCommandGetVimeoDirectURL,
	NMCommandGetCategoryThumbnail,
	NMCommandGetChannelThumbnail,
	NMCommandGetAuthorThumbnail,
	NMCommandGetVideoThumbnail,
	NMCommandGetPreviewThumbnail,
	NMCommandCheckUpdate,
	NMCommandPostSharing,
	NMCommandParseFacebookFeed,
} NMCommand;

typedef enum {
	NMVideoQueueStatusError			= -10,
	NMVideoQueueStatusNone			= 0,
	NMVideoQueueStatusResolvingDirectURL,
	NMVideoQueueStatusDirectURLReady,
	NMVideoQueueStatusQueued,
	NMVideoQueueStatusCurrentVideo,
	NMVideoQueueStatusPlayed,
} NMVideoQueueStatusType;

typedef enum {
	NMVideoQualityAutoSelect,
	NMVideoQualityAlwaysHD,
	NMVideoQualityAlwaysSD,
} NMVideoQualityType;

typedef enum {
	NMEventSubscribeChannel,
	NMEventUnsubscribeChannel,
	NMEventEnqueue,
	NMEventDequeue,
	NMEventShare,
	NMEventFavorite,
	NMEventUnfavorite,
	NMEventView,
	NMEventExamine,
} NMEventType;

typedef enum {
	NMErrorNone,
	NMErrorNoData,
	NMErrorNoSupportedVideoFormat,
	NMErrorDeviceTokenExpired,
	NMErrorYouTubeAPIError,
	NMErrorDequeueVideo,
	NMErrorUnfavoriteVideo,
} NMErrorType;

typedef enum {
	NMChannelUnknownType,
	NMChannelUserType,
	NMChannelTrendingType,
	NMChannelYouTubeType,
	NMChannelKeywordType,
	NMChannelVimeoType,
	NMChannelUserFacebookType,
	NMChannelUserTwitterType,
} NMChannelType;

typedef enum {
	NMLoginTwitterType,
	NMLoginFacebookType,
	NMLoginYouTubeType,
} NMSocialLoginType;

typedef enum {
	NMVideoSourceYouTube		= 1,
	NMVideoSourceVimeo,
} NMVideoSourceType;

typedef enum {
	NMVideoDoesNotExist,
	NMVideoExistsAndInChannel,
	NMVideoExistsButNotInChannel,
} NMVideoExistenceCheckResult;

extern BOOL NM_WIFI_REACHABLE;
extern NSString * NMServiceErrorDomain;
// Notifications
// error
extern NSString * const NMShowErrorAlertNotification;

// update check
extern NSString * const NMWillCheckUpdateNotification;
extern NSString * const NMDidCheckUpdateNotification;
extern NSString * const NMDidFailCheckUpdateNotification;

// token
extern NSString * const NMWillRequestTokenNotification;
extern NSString * const NMDidRequestTokenNotification;
extern NSString * const NMDidFailRequestTokenNotification;

// user
extern NSString * const NMWillCreateUserNotification;
extern NSString * const NMDidCreateUserNotification;
extern NSString * const NMDidFailCreateUserNotification;
//extern NSString * const NMWillEditUserNotification;
//extern NSString * const NMDidEditUserNotification;
//extern NSString * const NMDidFailEditUserNotification;
extern NSString * const NMWillVerifyUserNotification;
extern NSString * const NMDidVerifyUserNotification;
extern NSString * const NMDidFailVerifyUserNotification;
extern NSString * const NMWillDeauthorizeUserNotification;
extern NSString * const NMDidDeauthorizeUserNotification;
extern NSString * const NMDidFailDeauthorizeUserNotification;
extern NSString * const NMWillEditUserSettingsNotification;
extern NSString * const NMDidEditUserSettingsNotification;
extern NSString * const NMDidFailEditUserSettingsNotification;
extern NSString * const NMWillPollUserNotification;
extern NSString * const NMDidPollUserNotification;
extern NSString * const NMDidFailPollUserNotification;
extern NSString * const NMWillSynchronizeUserNotification;
extern NSString * const NMDidSynchronizeUserNotification;
extern NSString * const NMDidFailSynchronizeUserNotification;

// channel
extern NSString * const NMWillGetChannelsNotification;
extern NSString * const NMDidGetChannelsNotification;
extern NSString * const NMDidFailGetChannelsNotification;
extern NSString * const NMWillGetChannelWithIDNotification;
extern NSString * const NMDidGetChannelWithIDNotification;
extern NSString * const NMDidFailGetChannelWithIDNotification;
extern NSString * const NMWillGetChannelsForCategoryNotification;
extern NSString * const NMDidGetChannelsForCategoryNotification;
extern NSString * const NMDidFailGetChannelsForCategoryNotification;
extern NSString * const NMWillSearchChannelsNotification;
extern NSString * const NMDidSearchChannelsNotification;
extern NSString * const NMDidFailSearchChannelsNotification;
extern NSString * const NMWillGetFeaturedChannelsForCategories;
extern NSString * const NMDidGetFeaturedChannelsForCategories;
extern NSString * const NMDidFailGetFeaturedChannelsForCategories;
extern NSString * const NMWillCompareSubscribedChannelsNotification;
extern NSString * const NMDidCompareSubscribedChannelsNotification;
extern NSString * const NMDidFailCompareSubscribedChannelsNotification;

extern NSString * const NMWillGetChannelDetailNotification;
extern NSString * const NMDidGetChannelDetailNotification;
extern NSString * const NMDidFailGetChannelDetailNotification;
extern NSString * const NMWillCreateChannelNotification;
extern NSString * const NMDidCreateChannelNotification;
extern NSString * const NMDidFailCreateChannelNotification;
extern NSString * const NMWillPollChannelNotification;
extern NSString * const NMDidPollChannelNotification;
extern NSString * const NMDidFailPollChannelNotification;

// subscription
extern NSString * const NMWillSubscribeChannelNotification;
extern NSString * const NMDidSubscribeChannelNotification;
extern NSString * const NMDidFailSubscribeChannelNotification;
extern NSString * const NMWillUnsubscribeChannelNotification;
extern NSString * const NMDidUnsubscribeChannelNotification;
extern NSString * const NMDidFailUnsubscribeChannelNotification;
// sharing events
extern NSString * const NMWillShareVideoNotification;
extern NSString * const NMDidShareVideoNotification;
extern NSString * const NMDidFailShareVideoNotification;
extern NSString * const NMWillFavoriteVideoNotification;
extern NSString * const NMDidFavoriteVideoNotification;
extern NSString * const NMDidFailFavoriteVideoNotification;
extern NSString * const NMWillUnfavoriteVideoNotification;
extern NSString * const NMDidUnfavoriteVideoNotification;
extern NSString * const NMDidFailUnfavoriteVideoNotification;
extern NSString * const NMWillEnqueueVideoNotification;
extern NSString * const NMDidEnqueueVideoNotification;
extern NSString * const NMDidFailEnqueueVideoNotification;
extern NSString * const NMWillDequeueVideoNotification;
extern NSString * const NMDidDequeueVideoNotification;
extern NSString * const NMDidFailDequeueVideoNotification;
extern NSString * const NMWillPostSharingNotification;
extern NSString * const NMDidPostSharingNotification;
extern NSString * const NMDidFailPostSharingNotification;

// video
extern NSString * const NMWillGetChannelVideListNotification;
extern NSString * const NMDidGetChannelVideoListNotification;
extern NSString * const NMDidFailGetChannelVideoListNotification;
extern NSString * const NMDidCancelGetChannelVideListNotification;

extern NSString * const NMWillGetFeaturedCategoriesNotification;
extern NSString * const NMDidGetFeaturedCategoriesNotification;
extern NSString * const NMDidFailGetFeaturedCategoriesNotification;

extern NSString * const NMWillGetYouTubeDirectURLNotification;
extern NSString * const NMDidGetYouTubeDirectURLNotification;
extern NSString * const NMDidFailGetYouTubeDirectURLNotification;
extern NSString * const NMWillDownloadImageNotification;
extern NSString * const NMDidDownloadImageNotification;
extern NSString * const NMDidFailDownloadImageNotification;

extern NSString * const NMTaskFailNotification;
extern NSString * const NMDidFailSendEventNotification;

// Entity names
extern NSString * const NMCategoryEntityName;
extern NSString * const NMChannelEntityName;
extern NSString * const NMVideoEntityName;
extern NSString * const NMVideoDetailEntityName;
extern NSString * const NMConcreteVideoEntityName;
extern NSString * const NMAuthorEntityName;

// Playback Notification
extern NSString * const NMWillBeginPlayingVideoNotification;

// channel management subscribe and play notification
extern NSString * const NMShouldPlayNewlySubscribedChannelNotification;
