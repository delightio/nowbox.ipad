//
//  VideoViewController.m
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "VideoViewController.h"
#import "NMConcreteVideo.h"

@interface VideoViewController (PrivateMethods)
- (void)configureInfoView:(VideoInfoView *)infoView;
@end

@implementation VideoViewController

@synthesize portraitView;
@synthesize landscapeView;
@synthesize channel;
@synthesize video;

- (id)initWithChannel:(NMChannel *)aChannel video:(NMVideo *)aVideo nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.channel = aChannel;
        self.video = aVideo;
    }
    return self;
}

- (void)dealloc
{
    [portraitView release];
    [landscapeView release];
    [channel release];
    [video release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureInfoView:portraitView];
    [self configureInfoView:landscapeView];
    
    [self.view addSubview:portraitView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.portraitView = nil;
    self.landscapeView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [landscapeView removeFromSuperview];
        portraitView.frame = self.view.bounds;
        [self.view addSubview:portraitView];
    } else {
        [portraitView removeFromSuperview];
        landscapeView.frame = self.view.bounds;
        [self.view addSubview:landscapeView];
    }
}

#pragma mark - Private methods

- (void)configureInfoView:(VideoInfoView *)infoView
{
    infoView.channelTitleLabel.text = channel.title;
    infoView.videoTitleLabel.text = video.video.title;
}

#pragma mark - Actions

- (IBAction)gridButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:NO];
}

@end
