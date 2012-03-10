//
//  CommentShareView.h
//  ipad
//
//  Created by Chris Haugli on 3/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlowLabel.h"
#import "NMDataType.h"
#import "NMVideo.h"

@protocol CommentShareViewDelegate;

@interface CommentShareView : UIView <UITextViewDelegate> {
    BOOL dismissed;
    NSInteger timeElapsed;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIImageView *textViewBackground;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet GlowLabel *videoTitleLabel;
@property (nonatomic, retain) IBOutlet GlowLabel *authorLabel;
@property (nonatomic, retain) IBOutlet UILabel *characterCountLabel;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *emailButton;
@property (nonatomic, retain) NMVideo *video;
@property (nonatomic, assign) id<CommentShareViewDelegate> delegate;

- (void)setVideo:(NMVideo *)video timeElapsed:(NSInteger)timeElapsed;
- (IBAction)twitterButtonPressed:(id)sender;
- (IBAction)facebookButtonPressed:(id)sender;
- (IBAction)emailButtonPressed:(id)sender;
- (IBAction)touchAreaPressed:(id)sender;

@end

@protocol CommentShareViewDelegate <NSObject>
- (void)commentShareView:(CommentShareView *)commentShareView didSubmitText:(NSString *)text socialLogin:(NMSocialLoginType)socialLogin timeElapsed:(NSInteger)timeElapsed;
@optional
- (void)commentShareViewWillDismiss:(CommentShareView *)commentShareView;
- (void)commentShareViewDidDismiss:(CommentShareView *)commentShareView;
@end