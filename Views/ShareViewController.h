//
//  ShareViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/7/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMVideo.h"

typedef enum {
    ShareModeFacebook = 0,
    ShareModeTwitter = 1
} ShareMode;

@interface ShareViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate> {
    BOOL viewPushedByNavigationController;
}

@property (nonatomic, assign) ShareMode shareMode;
@property (nonatomic, retain) IBOutlet UITextView *messageText;
@property (nonatomic, retain) IBOutlet UILabel *characterCountLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *socialNetworkToggle;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) NMVideo *video;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger elapsedSeconds;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil video:(NMVideo *)aVideo duration:(NSInteger)aDuration elapsedSeconds:(NSInteger)anElapsedSeconds;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;

@end
