//
//  SHKFBLoginViewController.h
//  Nowmov
//
//  Created by Bill So on 26/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBConnect.h"


@interface SHKFBLoginViewController : UIViewController {
    FBSession * session;
	FBLoginDialog * dialog;
}

@property (nonatomic, retain) FBSession * session;

- (id)initWithSession:(FBSession *)aSession;

@end
