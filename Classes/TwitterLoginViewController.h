//
//  TwitterLoginViewController.h
//  ipad
//
//  Created by Bill So on 14/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterLoginViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *loginWebView;
}

@property (retain, nonatomic) IBOutlet UIWebView *loginWebView;

@end
