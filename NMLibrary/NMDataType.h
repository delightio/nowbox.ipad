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
	NMCommandGetChannelDetail,
	NMCommandCreateKeywordChannel,
	NMCommandCreateUser,
	NMCommandVerifyFacebookUser,
	NMCommandVerifyTwitterUser,
	NMCommandSendEvent,
	NMCommandGetFeaturedCategories,
//	NMCommandGetChannelVideoList,
	NMCommandGetMoreVideoForChannel,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetVimeoDirectURL,
	NMCommandGetChannelThumbnail,
	NMCommandGetAuthorThumbnail,
	NMCommandGetVideoThumbnail,
	NMCommandGetPreviewThumbnail,
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
	NMEventSubscribeChannel,
	NMEventUnsubscribeChannel,
	NMEventEnqueue,
	NMEventDequeue,
	NMEventShare,
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
} NMErrorType;

typedef enum {
	NMChannelUnknownType,
	NMChannelUserType,
	NMChannelYoutubeType,
	NMChannelKeywordType,
	NMChannelVimeoType,
} NMChannelType;


// Notifications
// user
extern NSString * const NMWillCreateUserNotification;
extern NSString * const NMDidCreateUserNotification;
extern NSString * const NMDidFailCreateUserNotification;

// channel
extern NSString * const NMWillGetChannelsNotification;
extern NSString * const NMDidGetChannelsNotification;
extern NSString * const NMDidFailGetChannelsNotification;
extern NSString * const NMWillGetChannelsForCategoryNotification;
extern NSString * const NMDidGetChannelsForCategoryNotification;
extern NSString * const NMDidFailGetChannelsForCategoryNotification;
extern NSString * const NMWillSearchChannelsNotification;
extern NSString * const NMDidSearchChannelsNotification;
extern NSString * const NMDidFailSearchChannelsNotification;
extern NSString * const NMWillGetChannelDetailNotification;
extern NSString * const NMDidGetChannelDetailNotification;
extern NSString * const NMDidFailGetChannelDetailNotification;
extern NSString * const NMWillCreateChannelNotification;
extern NSString * const NMDidCreateChannelNotification;
extern NSString * const NMDidFailCreateChannelNotification;

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
extern NSString * const NMWillUnfavoriteVideoNotification;
extern NSString * const NMDidUnfavoriteVideoNotification;
extern NSString * const NMDidFailUnfavoriteVideoNotification;
extern NSString * const NMWillEnqueueVideoNotification;
extern NSString * const NMDidEnqueueVideoNotification;
extern NSString * const NMDidFailEnqueueVideoNotification;
extern NSString * const NMWillDequeueVideoNotification;
extern NSString * const NMDidDequeueVideoNotification;
extern NSString * const NMDidFailDequeueVideoNotification;

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

extern NSString * const NMURLConnectionErrorNotification;

// Entity names
extern NSString * const NMCategoryEntityName;
extern NSString * const NMChannelEntityName;
extern NSString * const NMVideoEntityName;
extern NSString * const NMVideoDetailEntityName;

// Playback Notification
extern NSString * const NMWillBeginPlayingVideoNotification;

// channel management subscribe and play notification
extern NSString * const NMShouldPlayNewlySubscribedChannelNotification;
