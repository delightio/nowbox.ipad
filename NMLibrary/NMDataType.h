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
	NMCommandGetTrendingChannels,
	NMCommandGetVideoInfo,
	NMCommandGetChannelVideoList,
	NMCommandGetNextVideo,
	NMCommandGetVideoReason,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetVimeoDirectURL,
	NMCommandGetChannelThumbnail,
} NMCommand;

typedef enum {
	NMVideoQueueStatusNone,
	NMVideoQueueStatusResolvingDirectURL,
	NMVideoQueueStatusDirectURLReady,
	NMVideoQueueStatusQueued,
	NMVideoQueueStatusPlaying,
	NMVideoQueueStatusPlayed,
	NMVideoQueueStatusError			= 999,
} NMVideoQueueStatusType;

typedef enum {
	NMEventUpVote,
	NMEventDownVote,
	NMEventRewind,
	NMEventShare,
	NMEventView,
	NMEventViewing,
	NMEventReexamine,
} NMEventType;

typedef enum {
	NMErrorNone,
	NMVideoDirectURLResolutionError,
} NMErrorType;

// Notifications
extern NSString * const NMWillGetChannelsNotification;
extern NSString * const NMDidGetChannelsNotification;
extern NSString * const NMDidFailGetChannelNotification;
extern NSString * const NMWillGetChannelVideListNotification;
extern NSString * const NMDidGetChannelVideoListNotification;
extern NSString * const NMDidFailGetChannelVideoListNotification;
extern NSString * const NMWillRefreshChannelVideListNotification;
extern NSString * const NMDidRefreshChannelVideoListNotification;
extern NSString * const NMDidFailRefreshChannelVideoListNotification;

extern NSString * const NMWillGetYouTubeDirectURLNotification;
extern NSString * const NMDidGetYouTubeDirectURLNotification;
extern NSString * const NMDidFailGetYouTubeDirectURLNotification;
extern NSString * const NMWillGetVideoInfoNotification;
extern NSString * const NMDidGetVideoInfoNotification;
extern NSString * const NMWillDownloadImageNotification;
extern NSString * const NMDidDownloadImageNotification;
extern NSString * const NMDidFailDownloadImageNotification;

extern NSString * const NMTaskFailNotification;
extern NSString * const NMDidFailSendEventNotification;

extern NSString * const NMURLConnectionErrorNotification;

// Entity names
extern NSString * const NMChannelEntityName;
extern NSString * const NMVideoEntityName;