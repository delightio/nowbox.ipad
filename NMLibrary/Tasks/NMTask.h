//
//  NMTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataType.h"
#import "JSONKit.h"

#define NM_URL_REQUEST_TIMEOUT		30.0f
#define NM_BASE_URL					@"api.nowmov.com/1"

@class NMDataController;

/*!
 Parent class of all tasks.
 */
@interface NMTask : NSObject {
	NMTaskExecutionState state;
	NSMutableData * buffer;
	NSMutableArray * parsedObjects;
	NMCommand command;
	BOOL encountersErrorDuringProcessing;
	NSInteger httpStatusCode;
	NSNumber * targetID;
@private
	NSDateFormatter * _dateTimeFormatter;
	NSDateFormatter * _dateFormatter;
}

@property (nonatomic, readonly) BOOL encountersErrorDuringProcessing;
@property (nonatomic, readonly) NSDictionary * errorInfo;
@property (nonatomic) NSInteger httpStatusCode;
@property (assign) NMTaskExecutionState state;
@property (nonatomic, readonly) NMCommand command;
@property (nonatomic, readonly) NSMutableData * buffer;
@property (nonatomic, retain) NSNumber * targetID;

- (void)prepareDataBuffer;
- (void)clearDataBuffer;
- (NSMutableURLRequest *)URLRequest;
- (void)processDownloadedDataInBuffer;
- (void)saveProcessedDataInController:(NMDataController *)ctrl;
- (BOOL)checkDictionaryContainsError:(NSDictionary *)dict;
- (NSUInteger)commandIndex;

- (NSString *)willLoadNotificationName;
- (NSString *)didLoadNotificationName;
- (NSString *)didFailNotificationName;
- (NSDictionary *)userInfo;

@end
