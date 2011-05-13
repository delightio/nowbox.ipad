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
	NMEventUpVote,
	NMEventDownVote,
	NMEventRewind,
	NMEventShare,
	NMEventView,
	NMEventViewing,
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