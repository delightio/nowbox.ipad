//
//  CommentShareView.h
//  ipad
//
//  Created by Chris Haugli on 3/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMDataType.h"
#import "NMVideo.h"
#import "NMSocialInfo.h"
#import "NMCachedImageView.h"

@protocol CommentShareViewDelegate;

typedef enum {
    CommentShareServiceFacebook,
    CommentShareServiceTwitter,
    CommentShareServiceEmail
} CommentShareService;

typedef enum {
    CommentShareModeShare,
    CommentShareModeComment
} CommentShareMode;

@interface CommentShareView : UIView <UITextViewDelegate, UIAlertViewDelegate> {
    BOOL dismissed;
    BOOL loggingInTwitter;
    BOOL loggingInFacebook;

    NSInteger timeElapsed;
    
    NSString *defaultTwitterText;
    NSString *defaultFacebookText;
    NSString *defaultEmailText;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIView *thumbnailView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *thumbnailImage;
@property (nonatomic, retain) IBOutlet UIImageView *textViewBackground;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *characterCountLabel;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *emailButton;
@property (nonatomic, retain) IBOutlet UIButton *touchArea;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) NMVideo *video;
@property (nonatomic, retain) NMSocialInfo *socialInfo;
@property (nonatomic, assign) CommentShareService service;
@property (nonatomic, assign) CommentShareMode mode;
@property (nonatomic, assign) id<CommentShareViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame mode:(CommentShareMode)aMode;
- (void)setVideo:(NMVideo *)video timeElapsed:(NSInteger)timeElapsed;
- (void)dismiss;
- (IBAction)twitterButtonPressed:(id)sender;
- (IBAction)facebookButtonPressed:(id)sender;
- (IBAction)emailButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;

@end

@protocol CommentShareViewDelegate <NSObject>
- (void)commentShareView:(CommentShareView *)commentShareView didSubmitText:(NSString *)text service:(CommentShareService)service timeElapsed:(NSInteger)timeElapsed;
- (void)commentShareViewDidRequestTwitterLogin:(CommentShareView *)commentShareView;
- (void)commentShareViewDidRequestFacebookLogin:(CommentShareView *)commentShareView;
@optional
- (void)commentShareViewWillDismiss:(CommentShareView *)commentShareView;
- (void)commentShareViewDidDismiss:(CommentShareView *)commentShareView;
@end