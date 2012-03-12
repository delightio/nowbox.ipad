//
//  CommentShareView.m
//  ipad
//
//  Created by Chris Haugli on 3/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "CommentShareView.h"
#import "UIView+InteractiveAnimation.h"
#import "NMConcreteVideo.h"
#import "NMAuthor.h"
#import "NMAccountManager.h"
#import "Analytics.h"

#define kMaxTwitterCharacters 119

#define kDefaultFacebookText @"Watching \"%@\""
#define kDefaultTwitterText @"Watching \"%@\" http://youtu.be/%@"
#define kDefaultEmailText @"Check out this video: %@"

#define kLastCommentServiceUserDefaultsKey @"NM_COMMENT_LAST_SERVICE"
#define kLastShareServiceUserDefaultsKey @"NM_SHARE_LAST_SERVICE"

@implementation CommentShareView

@synthesize contentView;
@synthesize textViewBackground;
@synthesize textView;
@synthesize videoTitleLabel;
@synthesize authorLabel;
@synthesize characterCountLabel;
@synthesize twitterButton;
@synthesize facebookButton;
@synthesize emailButton;
@synthesize touchArea;
@synthesize activityIndicator;
@synthesize video;
@synthesize service;
@synthesize mode;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame mode:(CommentShareMode)aMode
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"CommentShareView" owner:self options:nil];
        contentView.frame = self.bounds;
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        self.clipsToBounds = NO;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(handleDidShareVideoNotification:) name:NMDidPostNewFacebookLinkNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(handleDidFailShareVideoNotification:) name:NMDidFailPostNewFacebookLinkNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(handleDidShareVideoNotification:) name:NMDidPostTweetNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(handleDidFailShareVideoNotification:) name:NMDidFailPostTweetNotification object:nil];

        self.mode = aMode;
        
        videoTitleLabel.glowColor = [UIColor blackColor];
        authorLabel.glowColor = [UIColor blackColor];
        textViewBackground.image = [textViewBackground.image stretchableImageWithLeftCapWidth:3 topCapHeight:3];
        
        // Restore last service used
        CommentShareService lastService = [[NSUserDefaults standardUserDefaults] integerForKey:(mode == CommentShareModeComment ?
                                                                                                kLastCommentServiceUserDefaultsKey : 
                                                                                                kLastShareServiceUserDefaultsKey)];
        [self setService:lastService];
        
        // Hide inactive services
        if ([[NMAccountManager sharedAccountManager].twitterAccountStatus integerValue] == 0) {
            twitterButton.hidden = YES;
            if (service == CommentShareServiceTwitter) {
                self.service = CommentShareServiceFacebook;
            }
        }
        if ([[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue] == 0) {
            facebookButton.hidden = YES;
            if (service == CommentShareServiceFacebook) {
                self.service = CommentShareServiceEmail;
            }
        }
        if (mode == CommentShareModeComment && service == CommentShareServiceEmail) {
            self.service = (!twitterButton.hidden ? CommentShareServiceTwitter : CommentShareServiceFacebook);
        }
        
        // Size the text view and show the keyboard
        [self textViewDidChange:textView];
        [textView becomeFirstResponder];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame mode:CommentShareModeShare];
}

- (void)dealloc
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:service forKey:(mode == CommentShareModeComment ?
                                             kLastCommentServiceUserDefaultsKey : 
                                             kLastShareServiceUserDefaultsKey)];
    [userDefaults synchronize];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [defaultTwitterText release];
    [defaultFacebookText release];
    [defaultEmailText release];
    [contentView release];
    [textViewBackground release];
    [textView release];
    [videoTitleLabel release];
    [authorLabel release];
    [twitterButton release];
    [facebookButton release];
    [emailButton release];
    [touchArea release];
    [activityIndicator release];
    
    [super dealloc];
}

- (void)setVideo:(NMVideo *)aVideo
{
    if (video != aVideo) {
        [video release];
        video = [aVideo retain];
        
        videoTitleLabel.text = video.video.title;
        authorLabel.text = video.video.author.username;
        
        [defaultTwitterText release];
        [defaultFacebookText release];
        [defaultEmailText release];
        defaultTwitterText = [[NSString alloc] initWithFormat:kDefaultTwitterText, video.video.title, video.video.external_id];
        defaultFacebookText = [[NSString alloc] initWithFormat:kDefaultFacebookText, video.video.title];
        defaultEmailText = [[NSString alloc] initWithFormat:kDefaultEmailText, video.video.title];

        // Forces update of placeholder text
        [self setService:service];
    }
}

- (void)setVideo:(NMVideo *)aVideo timeElapsed:(NSInteger)aTimeElapsed
{
    [self setVideo:aVideo];
    timeElapsed = aTimeElapsed;
}

- (void)setService:(CommentShareService)aService
{
    service = aService;
    
    twitterButton.selected = (service == CommentShareServiceTwitter);
    facebookButton.selected = (service == CommentShareServiceFacebook);
    emailButton.selected = (service == CommentShareServiceEmail);
    characterCountLabel.hidden = (service != CommentShareServiceTwitter);
    
    // Update placeholder text if user hasn't typed anything
    if ([textView.text length] == 0 || 
        [textView.text isEqualToString:defaultTwitterText] || 
        [textView.text isEqualToString:defaultFacebookText] ||
        [textView.text isEqualToString:defaultEmailText]) {
        switch (service) {
            case CommentShareServiceTwitter:
                textView.text = defaultTwitterText;
                break;
            case CommentShareServiceFacebook:
                textView.text = defaultFacebookText;
                break;
            case CommentShareServiceEmail:
                textView.text = defaultEmailText;
                break;
        }
    }
}

- (void)setMode:(CommentShareMode)aMode
{
    mode = aMode;
    emailButton.hidden = (mode == CommentShareModeComment);
}

#pragma mark - IBActions

- (IBAction)twitterButtonPressed:(id)sender
{
    [self setService:CommentShareServiceTwitter];
}

- (IBAction)facebookButtonPressed:(id)sender
{
    [self setService:CommentShareServiceFacebook];
}

- (IBAction)emailButtonPressed:(id)sender
{
    [self setService:CommentShareServiceEmail];
}

- (IBAction)touchAreaPressed:(id)sender
{
    dismissed = YES;
    [textView resignFirstResponder];
}

#pragma mark - Notifications

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (dismissed) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];        
        if ([delegate respondsToSelector:@selector(commentShareViewWillDismiss:)]) {
            [delegate commentShareViewWillDismiss:self];
        }
    }

    NSDictionary *userInfo = [notification userInfo];
    float animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInSuperview = [self.superview convertRect:keyboardFrame fromView:nil];    
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         self.frame = CGRectMake(keyboardFrameInSuperview.origin.x, 
                                                 keyboardFrameInSuperview.origin.y - (dismissed ? 0 : self.frame.size.height),
                                                 keyboardFrameInSuperview.size.width, 
                                                 self.frame.size.height);                             
                      }
                      completion:^(BOOL finished){
                          if (dismissed) {
                              if ([delegate respondsToSelector:@selector(commentShareViewDidDismiss:)]) {
                                  [delegate commentShareViewDidDismiss:self];
                              }
                          }
                      }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self keyboardWillChangeFrame:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self keyboardWillChangeFrame:notification];
}

- (void)orientationChanged:(NSNotification *)notification
{
    [self textViewDidChange:textView];
}

- (void)handleDidShareVideoNotification:(NSNotification *)aNotification 
{
    [activityIndicator stopAnimating];
    [self touchAreaPressed:nil];
}

- (void)handleDidFailShareVideoNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Sorry, but something went wrong and your message could not be %@. Please try again a bit later.", 
                                                                 (service == CommentShareServiceFacebook ? @"posted" : @"tweeted")]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];

    [activityIndicator stopAnimating];
}

#pragma mark - UIView methods

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Accept all points above the view so that we may dismiss it by tapping in that area
    if (point.y < 0) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (point.y < 0) {
        return touchArea;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)aTextView
{
    NSInteger remainingCharacters = kMaxTwitterCharacters - [[aTextView text] length];
    characterCountLabel.text = [NSString stringWithFormat:@"%i", remainingCharacters];
    
    if (remainingCharacters < 0) {
        characterCountLabel.textColor = [UIColor redColor];
    } else {
        characterCountLabel.textColor = [UIColor colorWithWhite:0.73 alpha:1.0];
    }
    
    // Do we need to increase the size of our view to fit more text?
    if (dismissed) return;
    
    CGFloat contentOffset = aTextView.contentOffset.y;
    CGRect frame = aTextView.frame;
    aTextView.frame = CGRectMake(aTextView.frame.origin.x, aTextView.frame.origin.y, aTextView.frame.size.width, 1000);
    [aTextView sizeToFit];
    CGFloat heightDifference = aTextView.frame.size.height - frame.size.height;
    CGFloat newViewHeight = self.frame.size.height + heightDifference;
    CGFloat maxNewViewHeight = self.frame.origin.y + self.frame.size.height;
    aTextView.frame = frame;
    newViewHeight = MAX(MIN(newViewHeight, maxNewViewHeight), 150);

    if (newViewHeight != self.frame.size.height) {
        [UIView animateWithInteractiveDuration:0.15
                                    animations:^{
                                        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y + self.frame.size.height - newViewHeight, self.frame.size.width, newViewHeight);
                                    }
                                    completion:^(BOOL finished){
                                        if (newViewHeight < maxNewViewHeight) {
                                            aTextView.scrollEnabled = NO;
                                            aTextView.contentOffset = CGPointZero;
                                        } else {
                                            aTextView.scrollEnabled = YES;
                                            aTextView.contentOffset = CGPointMake(aTextView.contentOffset.x, contentOffset);            
                                        }                             
                                    }];        
    } else {
        aTextView.contentOffset = CGPointMake(aTextView.contentOffset.x, contentOffset);        
    }
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Newline == return button pressed
    if ([text isEqualToString:@"\n"] && ![activityIndicator isAnimating]) {
        switch (service) {
            case CommentShareServiceTwitter:
                if ([aTextView.text length] <= kMaxTwitterCharacters) {
                    [delegate commentShareView:self didSubmitText:aTextView.text service:service timeElapsed:timeElapsed];
                    [activityIndicator startAnimating];
                }
                break;
            case CommentShareServiceFacebook:
                [delegate commentShareView:self didSubmitText:aTextView.text service:service timeElapsed:timeElapsed];
                [activityIndicator startAnimating];
                break;
            case CommentShareServiceEmail:
                [delegate commentShareView:self didSubmitText:aTextView.text service:service timeElapsed:timeElapsed];
                [self touchAreaPressed:nil];
                break;
        }

        return NO;
    }
    
    return YES;
}

@end
