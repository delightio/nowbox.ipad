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

#define kMaxTwitterCharacters 119

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
        
        [self textViewDidChange:textView];
        [textView becomeFirstResponder];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contentView release];
    [textViewBackground release];
    [textView release];
    [videoTitleLabel release];
    [authorLabel release];
    [twitterButton release];
    [facebookButton release];
    [emailButton release];
    
    [super dealloc];
}

- (void)setVideo:(NMVideo *)aVideo
{
    if (video != aVideo) {
        [video release];
        video = [aVideo retain];
        
        videoTitleLabel.text = video.video.title;
        authorLabel.text = video.video.author.username;
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
}

- (IBAction)facebookButtonPressed:(id)sender
{
    twitterButton.selected = NO;
    facebookButton.selected = YES;
    emailButton.selected = NO;
    characterCountLabel.hidden = YES;    
}

- (IBAction)emailButtonPressed:(id)sender
{
    twitterButton.selected = NO;
    facebookButton.selected = NO;
    emailButton.selected = YES;
    characterCountLabel.hidden = YES;    
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
