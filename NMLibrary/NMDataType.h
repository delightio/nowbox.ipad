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
	NMCommandGetChannels			= 1,
	NMCommandGetVideoInfo,
	NMCommandGetChannelVideoList,
	NMCommandGetNextVideo,
	NMCommandGetVideoReason,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetVimeoDirectURL,
} NMCommand;

typedef enum {
	NMEventUpVote,
	NMEventDownVote,
	NMEventRewind,
	NMEventShare,
	NMEventView,
} NMEventType;

// Notifications
extern NSString * const NMWillGetChannelsNotification;
extern NSString * const NMDidGetChannelsNotification;
extern NSString * const NMWillGetChannelVideListNotification;
extern NSString * const NMDidGetChannelVideoListNotification;
extern NSString * const NMWillGetYouTubeDirectURLNotification;
extern NSString * const NMDidGetYouTubeDirectURLNotification;
extern NSString * const NMWillGetVideoInfoNotification;
extern NSString * const NMDidGetVideoInfoNotification;

extern NSString * const NMTaskFailNotification;

// Entity names
extern NSString * const NMChannelEntityName;
extern NSString * const NMVideoEntityName;