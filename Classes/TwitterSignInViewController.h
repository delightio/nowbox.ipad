//
//  TwitterSignInViewController.h
//  ipad
//
//  Created by Bill So on 31/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OAuthConsumer.h"


@interface TwitterSignInViewController : UIViewController <UIWebViewDelegate> {
    UIWebView * webView;
	OAConsumer * consumer;
	OAToken * requestToken;
	OAToken * accessToken;
	NSString * callbackURLString;
}

@property (nonatomic, retain) OAToken *requestToken;
@property (nonatomic, retain) OAToken *accessToken;
@property (nonatomic, retain) NSString * callbackURLString;

@end
