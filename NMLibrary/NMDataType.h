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
	NMCommandGetChannelVideos,
	NMCommandGetNextVideo,
	NMCommandGetVideoReason,
	NMCommandGetYouTubeDirectURL,
	NMCommandGetVimeoDirectURL,
} NMCommand;