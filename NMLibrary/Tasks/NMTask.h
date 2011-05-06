//
//  NMTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataType.h"
#import "JSONKit.h"

#define NM_URL_REQUEST_TIMEOUT		20.0f

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
	id notificationSender;
@private
	NSDateFormatter * _dateTimeFormatter;
	NSDateFormatter * _dateFormatter;
}

@property (nonatomic, readonly) BOOL encountersErrorDuringProcessing;
@property (nonatomic, readonly) NSDictionary * errorInfo;
@property (nonatomic) NSInteger httpStatusCode;
@property (nonatomic, assign) NMTaskExecutionState state;
@property (nonatomic, readonly) NMCommand command;
@property (nonatomic, readonly) NSMutableData * buffer;
@property (nonatomic, retain) id notificationSender;

- (void)prepareDataBuffer;
- (void)clearDataBuffer;
- (NSMutableURLRequest *)URLRequest;
- (void)processDownloadedDataInBuffer;
- (void)saveProcessedDataInController:(NMDataController *)ctrl;
- (BOOL)checkDictionaryContainsError:(NSDictionary *)dict;

- (NSString *)willLoadNotificationName;
- (NSString *)didLoadNotificationName;
- (NSString *)didFailNotificationName;
- (NSDictionary *)userInfo;

@end
