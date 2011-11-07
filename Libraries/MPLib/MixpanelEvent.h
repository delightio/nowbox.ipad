//
//  MixpanelEvent.h
//  MPLib
//
//

#import <Foundation/Foundation.h>
#import "Analytics.h"
@interface MixpanelEvent : NSObject<NSCoding> {
	NSString *name;
	NSMutableDictionary *properties;
	NSDate *timestamp;
}
- (id) initWithName:(NSString*) name properties:(NSDictionary*) properties;
- (NSDictionary*) dictionaryValue;
@end
