//
//  NMTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataType.h"

@interface NMTask : NSObject {
	NMTaskExecutionState state;
	NSMutableData * buffer;
	NMCommand command;
@private
	NSDateFormatter * _dateTimeFormatter;
	NSDateFormatter * _dateFormatter;
}

@property (nonatomic, assign) NMTaskExecutionState state;
@property (nonatomic, readonly) NMCommand command;
@property (nonatomic, readonly) NSMutableData * buffer;

@end
