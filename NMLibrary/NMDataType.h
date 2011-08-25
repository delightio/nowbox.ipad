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
	NMCommandGetFriendChannels,
	NMCommandGetTopicChannels,
	NMCommandGetSubscribedChannels,
	NMCommandGetChannelsForCategory,
	NMCommandSearchChannels,
	NMCommandSendEvent,
	NMCommandGetFeaturedCategories,
	NMCommandGetChannelVideoList,
	NMCommandGetMoreVideoForChannel,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetVimeoDirectURL,
	NMCommandGetChannelThumbnail,
	NMCommandGetAuthorThumbnail,
} NMCommand;

typedef enum {
	NMVideoQueueStatusError			= -10,
	NMVideoQueueStatusNone			= 0,
	NMVideoQueueStatusResolvingDirectURL,
	NMVideoQueueStatusDirectURLReady,
	NMVideoQueueStatusQueued,
	NMVideoQueueStatusPlaying,
	NMVideoQueueStatusPlayed,
} NMVideoQueueStatusType;

typedef enum {
	NMEventSubscribeChannel,
	NMEventUnsubscribeChannel,
	NMEventEnqueue,
	NMEventDequeue,
	NMEventShare,
	NMEventView,
	NMEventExamine,
} NMEventType;

typedef enum {
	NMErrorNone,
	NMErrorNoData,
	NMErrorNoSupportedVideoFormat,
	NMErrorYouTubeAPIError,
} NMErrorType;


// Notifications
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
extern NSString * const NMWillGetMoreChannelVideNotification;
extern NSString * const NMDidGetMoreChannelVideoNotification;
extern NSString * const NMDidFailGetMoreChannelVideoNotification;

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
