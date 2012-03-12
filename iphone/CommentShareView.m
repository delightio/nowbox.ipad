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

#define kMaxTwitterCharacters 119
#define kDefaultFacebookText @"Watching \"%@\""
#define kDefaultTwitterText @"Watching \"%@\" http://youtu.be/%@"
#define kDefaultEmailText @"Check out this video: %@"

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
@synthesize video;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
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
        
        videoTitleLabel.glowColor = [UIColor blackColor];
        authorLabel.glowColor = [UIColor blackColor];
        textViewBackground.image = [textViewBackground.image stretchableImageWithLeftCapWidth:3 topCapHeight:3];
        
        // User may not be logged into all accounts. Hide inactive service buttons for now.
        [self twitterButtonPressed:nil];
        if ([[NMAccountManager sharedAccountManager].twitterAccountStatus integerValue] == 0) {
            twitterButton.hidden = YES;
            [self facebookButtonPressed:nil];
        }
        if ([[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue] == 0) {
            facebookButton.hidden = YES;
            if (facebookButton.selected) {
                [self emailButtonPressed:nil];
            }
        }
        
        // Size the text view and show the keyboard
        [self textViewDidChange:textView];
        [textView becomeFirstResponder];
    }
    return self;
}

- (void)dealloc
{
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

        if (facebookButton.selected) {
            [self facebookButtonPressed:nil];
        } else if (twitterButton.selected) {
            [self twitterButtonPressed:nil];
        } else {
            [self emailButtonPressed:nil];
        }
    }
}

- (void)setVideo:(NMVideo *)aVideo timeElapsed:(NSInteger)aTimeElapsed
{
    [self setVideo:aVideo];
    timeElapsed = aTimeElapsed;
}

#pragma mark - IBActions

- (IBAction)twitterButtonPressed:(id)sender
{
    twitterButton.selected = YES;
    facebookButton.selected = NO;
    emailButton.selected = NO;
    characterCountLabel.hidden = NO;
    
    if ([textView.text length] == 0 || [textView.text isEqualToString:defaultFacebookText] || [textView.text isEqualToString:defaultEmailText]) {
        textView.text = defaultTwitterText;
    }
}

- (IBAction)facebookButtonPressed:(id)sender
{
    twitterButton.selected = NO;
    facebookButton.selected = YES;
    emailButton.selected = NO;
    characterCountLabel.hidden = YES;   
    
    if ([textView.text length] == 0 || [textView.text isEqualToString:defaultTwitterText] || [textView.text isEqualToString:defaultEmailText]) {
        textView.text = defaultFacebookText;
    }
}

- (IBAction)emailButtonPressed:(id)sender
{
    twitterButton.selected = NO;
    facebookButton.selected = NO;
    emailButton.selected = YES;
    characterCountLabel.hidden = YES;
    
    if ([textView.text length] == 0 || [textView.text isEqualToString:defaultTwitterText] || [textView.text isEqualToString:defaultFacebookText]) {
        textView.text = defaultEmailText;
    }
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
    if ([text isEqualToString:@"\n"]) {
        if (facebookButton.selected) {
            [delegate commentShareView:self didSubmitText:aTextView.text socialLogin:NMLoginFacebookType timeElapsed:timeElapsed];
        } else if (twitterButton.selected) {
            [delegate commentShareView:self didSubmitText:aTextView.text socialLogin:NMLoginTwitterType timeElapsed:timeElapsed];
        } else {
            // Email sharing: TODO
        }
        [self touchAreaPressed:nil];
        return NO;
    }
    
    return YES;
}

@end
