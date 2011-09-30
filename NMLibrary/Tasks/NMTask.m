//
//  NMTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

NSString * const NMTaskFailNotification = @"NMTaskFailNotification";

@implementation NMTask

@synthesize state, command, buffer;
@synthesize encountersErrorDuringProcessing;
@synthesize executeSaveActionOnError;
@synthesize httpStatusCode;
@synthesize errorInfo;
@synthesize targetID;


- (NSDate *)dateTimeFromString:(NSString *)str {
	if ( _dateTimeFormatter == nil ) {
		_dateTimeFormatter = [[NSDateFormatter alloc] init];
		[_dateTimeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
		[_dateTimeFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	}
	return [_dateTimeFormatter dateFromString:str];
}

- (NSDate *)dateFromString:(NSString *)str {
	if ( _dateFormatter == nil ) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd"];
	}
	return [_dateFormatter dateFromString:str];
}

- (void)prepareDataBuffer {
	if ( buffer ) {
		[buffer setLength:0];
	} else {
		buffer = [[NSMutableData alloc] init];
	}
}

- (void)clearDataBuffer {
	if ( buffer ) {
		[buffer release];
		buffer = nil;
	}
}

- (void)dealloc {
	[targetID release];
	[_dateFormatter release];
	[_dateTimeFormatter release];
	[buffer release];
	[parsedObjects release];
	[errorInfo release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	return nil;
}

- (void)processDownloadedDataInBuffer {
	return;
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return NO;
}

- (BOOL)checkDictionaryContainsError:(NSDictionary *)dict {
	NSNumber * c = [dict valueForKeyPath:@"status.code"];
	encountersErrorDuringProcessing = ( c == nil || [c integerValue] );
	return encountersErrorDuringProcessing;
}

- (NSUInteger)commandIndex {
	if ( targetID ) {
		NSUInteger tid = [self.targetID unsignedIntegerValue];
		return tid << 5 | (NSUInteger)command;
	}
	return (NSUInteger)command;
}

- (NSString *)willLoadNotificationName {
	return nil;
}

- (NSString *)didLoadNotificationName {
	return nil;
}

- (NSString *)didFailNotificationName {
	return NMTaskFailNotification;
}

- (NSString *)didCancelNotificationName {
	return nil;
}

- (NSDictionary *)userInfo {
	return nil;
}

- (NSDictionary *)failUserInfo {
	return nil;
}

- (NSDictionary *)cancelUserInfo {
	return nil;
}

@end
