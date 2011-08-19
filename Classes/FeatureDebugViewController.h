//
//  SearchDebugViewController.h
//  ipad
//
//  Created by Bill So on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"

@interface FeatureDebugViewController : UIViewController {
	NMChannel * targetChannel;
}

@property (nonatomic, retain) NMChannel * targetChannel;

- (IBAction)submitSearch:(id)sender;
- (IBAction)submitSubscribeChannel:(id)sender;
- (IBAction)submitUnsubscribeChannel:(id)sender;
- (IBAction)getCurrentSubscription:(id)sender;

@end
