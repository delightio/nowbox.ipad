//
//  SocialLoginViewController.h
//  ipad
//
//  Created by Bill So on 14/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//


typedef enum {
	LoginTwitterType,
	LoginFacebookType,
} SocialLoginType;

@interface SocialLoginViewController : UIViewController <UIWebViewDelegate> {
	IBOutlet UIActivityIndicatorView * loadingIndicator;
	IBOutlet UILabel * progressLabel;
	UIWebView *loginWebView;
	UIView * progressContainerView;
	SocialLoginType loginType;
}

@property (retain, nonatomic) IBOutlet UIWebView *loginWebView;
@property (nonatomic, retain) IBOutlet UIView * progressContainerView;
@property (nonatomic, assign) SocialLoginType loginType;

@end
