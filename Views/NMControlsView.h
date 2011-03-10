//
//  NMControlsView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NMControlsView : UIView {
	SEL action;
	id target;
}

- (void)addTarget:(id)atarget action:(SEL)anAction;

@end
