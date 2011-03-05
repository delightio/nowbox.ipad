//
//  NMTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"


@implementation NMTask

@synthesize state, command, buffer;
@synthesize encountersErrorDuringProcessing;
@synthesize httpStatusCode;


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
	[_dateFormatter release];
	[_dateTimeFormatter release];
	[buffer release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	return nil;
}

- (id)processDownloadedDataInBuffer {
	return nil;
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	
}

- (NSString *)willLoadNotificationName {
	return nil;
}

- (NSString *)didLoadNotificationName {
	return nil;
}

- (NSString *)didFailNotificationName {
	return nil;
}

- (NSDictionary *)userInfo {
	return nil;
}

@end
