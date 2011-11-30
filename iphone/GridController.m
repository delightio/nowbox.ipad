//
//  GridController.m
//  ipad
//
//  Created by Chris Haugli on 11/29/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridController.h"
#import "NMTaskQueueController.h"
#import "UIView+InteractiveAnimation.h"

@implementation GridController

@synthesize view;
@synthesize gridView;
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize itemArray;
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"GridController" owner:self options:nil];
        gridView.itemSize = CGSizeMake(100, 50);
        gridView.numberOfColumns = 0;
        
        dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
        self.currentChannel = nil;
    }
    return self;
}

- (void)dealloc
{
    [view release];
    [gridView release];
    [currentChannel release];
    [currentVideo release];
    [itemArray release];
    
    [super dealloc];
}

- (void)setCurrentChannel:(NMChannel *)aCurrentChannel
{
    if (currentChannel != aCurrentChannel) {
        [currentChannel release];
        currentChannel = [aCurrentChannel retain];
    }
    
    self.currentVideo = nil;
    
    if (currentChannel) {
        self.itemArray = [dataController sortedVideoListForChannel:aCurrentChannel];
    } else {
        self.itemArray = [dataController subscribedChannels];
    }
    
    [gridView reloadData];
}

- (void)setCurrentVideo:(NMVideo *)aCurrentVideo
{    
    if (currentVideo != aCurrentVideo) {
        [currentVideo release];
        currentVideo = [aCurrentVideo retain];
    }
    
    if (currentVideo) {
        self.itemArray = [dataController sortedVideoListForChannel:aCurrentVideo.channel];
        [gridView reloadData];
    }
}

#pragma mark - Navigation

- (void)slideGridForward:(BOOL)forward
{
    GridScrollView *newGridView = [[gridView copy] autorelease];
    newGridView.frame = CGRectOffset(gridView.frame, (forward ? 1 : -1) * gridView.frame.size.width, 0);
    [view addSubview:newGridView];
     
    [UIView animateWithInteractiveDuration:0.5
                                animations:^{
                                    newGridView.frame = gridView.frame;
                                    gridView.frame = CGRectOffset(gridView.frame, (forward ? -1 : 1) * gridView.frame.size.width, 0);
                                }
                                completion:^(BOOL finished){
                                    [gridView removeFromSuperview];
                                    self.gridView = newGridView;
                                }];    
}

- (void)pushToChannel:(NMChannel *)channel
{
    self.currentChannel = channel;
    [self slideGridForward:YES];
}

- (void)pushToVideo:(NMVideo *)video
{
    if (currentVideo) {
        self.currentVideo = video;
        [self slideGridForward:YES];
    } else {
        self.currentVideo = video;
        [gridView reloadData];
    }
}

- (void)pop
{
    // Go back a level
    if (currentVideo) {
        self.currentVideo = nil;
    } else if (currentChannel) {
        self.currentChannel = nil;
    }
    
    [self slideGridForward:NO];
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return [itemArray count];
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    UIButton *button = (UIButton *)[gridScrollView dequeueReusableSubview];
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    button.tag = index;
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [itemArray objectAtIndex:index];
        [button setTitle:video.title forState:UIControlStateNormal];
    } else {
        // We're on the channels page
        NMChannel *channel = [itemArray objectAtIndex:index];
        [button setTitle:channel.title forState:UIControlStateNormal];        
    }

    return button;
}

- (void)buttonPressed:(id)sender
{
    NSInteger index = [sender tag];
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [itemArray objectAtIndex:index];
        [delegate gridController:self didSelectVideo:video];
        //[self pushToVideo:video];
    } else {
        // We're on the channels page
        NMChannel *channel = [itemArray objectAtIndex:index];
        [delegate gridController:self didSelectChannel:channel];
        //[self pushToChannel:channel];
    }       
}

@end
