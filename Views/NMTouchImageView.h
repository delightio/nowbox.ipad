//
//  NMTouchImageView.h
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NMTouchImageView : UIImageView {
	CALayer * highlightLayer;
	SEL action;
	id target;
	
}

- (void)addTarget:(id)aTarget action:(SEL)anAction;

@end
