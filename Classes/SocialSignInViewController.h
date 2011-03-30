//
//  SocialSignInViewController.h
//  Nowmov
//
//  Created by Bill So on 24/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBConnect.h"


@interface SocialSignInViewController : UIViewController <FBSessionDelegate> {
    
}

- (IBAction)connectFacebook:(id)sender;
- (IBAction)connectTwitter:(id)sender;

@end
