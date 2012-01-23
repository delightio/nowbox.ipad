//
//  SocialLoginViewController.h
//  ipad
//
//  Created by Bill So on 14/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//
#import "NMLibrary.h"
#import <Accounts/Accounts.h>

@interface SocialLoginViewController : UIViewController <UIWebViewDelegate> {
	IBOutlet UIActivityIndicatorView * loadingIndicator;
	IBOutlet UILabel * progressLabel;
	UIWebView *loginWebView;
	UIView * progressContainerView;
	NMSocialLoginType loginType;
	ACAccountStore * accountStore;
	
	NSNotificationCenter * defaultCenter;
    
    BOOL loadingPageLoading;
	BOOL appFirstLaunch;
}

@property (retain, nonatomic) IBOutlet UIWebView *loginWebView;
@property (nonatomic, retain) IBOutlet UIView * progressContainerView;
@property (nonatomic, assign) NMSocialLoginType loginType;
@property (nonatomic, retain) ACAccountStore * accountStore;

@end
