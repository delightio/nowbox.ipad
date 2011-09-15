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
#define NM_BASE_URL					@"api.nowbox.com/1"

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
	NSDictionary * errorInfo;
	// executeSaveActionOnError - default to NO. If YES, the data controller will still execute saveProcessedDataInController: method even when it encounters error during processing of data. Error notificaiton is not sent when this flag is set YES.
	BOOL executeSaveActionOnError;
@private
	NSDateFormatter * _dateTimeFormatter;
	NSDateFormatter * _dateFormatter;
}

@property (nonatomic, readonly) BOOL encountersErrorDuringProcessing;
@property (nonatomic, readonly) BOOL executeSaveActionOnError;
@property (nonatomic, retain) NSDictionary * errorInfo;
@property (nonatomic) NSInteger httpStatusCode;
@property (assign) NMTaskExecutionState state;
@property (nonatomic, readonly) NMCommand command;
@property (nonatomic, readonly) NSMutableData * buffer;
@property (nonatomic, retain) NSNumber * targetID;

- (void)prepareDataBuffer;
- (void)clearDataBuffer;
- (NSMutableURLRequest *)URLRequest;
- (void)processDownloadedDataInBuffer;
- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl;
- (BOOL)checkDictionaryContainsError:(NSDictionary *)dict;
- (NSUInteger)commandIndex;

- (NSString *)willLoadNotificationName;
- (NSString *)didLoadNotificationName;
- (NSString *)didFailNotificationName;
- (NSDictionary *)userInfo;

@end
