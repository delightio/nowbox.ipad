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
    BOOL autoPost;
    BOOL firstShare;
}

@property (nonatomic, assign) ShareMode shareMode;
@property (nonatomic, retain) IBOutlet UITextView *messageText;
@property (nonatomic, retain) IBOutlet UILabel *characterCountLabel;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;
@property (nonatomic, retain) IBOutlet UIButton *shareButton;
@property (nonatomic, retain) IBOutlet UIView *progressView;
@property (nonatomic, retain) NMVideo *video;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger elapsedSeconds;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil video:(NMVideo *)aVideo duration:(NSInteger)aDuration elapsedSeconds:(NSInteger)anElapsedSeconds;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;
- (IBAction)facebookButtonPressed:(id)sender;
- (IBAction)twitterButtonPressed:(id)sender;

@end
