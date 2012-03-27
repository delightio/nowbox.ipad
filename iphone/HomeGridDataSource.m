//
//  HomeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "HomeGridDataSource.h"
#import "YouTubeGridDataSource.h"
#import "FacebookGridDataSource.h"
#import "TwitterGridDataSource.h"
#import "YouTubeAccountStatusViewController.h"
#import "SocialLoginViewController.h"
#import "NMAccountManager.h"
#import "Analytics.h"

@interface HomeGridDataSource (PrivateMethods)
- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel isUpdate:(BOOL)isUpdate;
@end

@implementation HomeGridDataSource

@synthesize fetchedResultsController;

- (id)initWithGridView:(PagingGridView *)aGridView viewController:(UIViewController *)aViewController managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    self = [super initWithGridView:aGridView managedObjectContext:aManagedObjectContext];
    if (self) {
        viewController = aViewController;
        refreshingChannels = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetChannelVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetChannelVideoListNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];
        
        [[NMAccountManager sharedAccountManager] addObserver:self forKeyPath:@"facebookAccountStatus" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc
{    
    [[NMAccountManager sharedAccountManager] removeObserver:self forKeyPath:@"facebookAccountStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [fetchedResultsController release];
    [refreshingChannels release];
    
    [super dealloc];
}

- (NMChannel *)selectObjectAtIndex:(NSUInteger)gridIndex
{
    NMAccountManager *accountManager = [NMAccountManager sharedAccountManager];
    NSUInteger frcObjectCount = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    NSUInteger index = [self mappedFetchedResultsIndexForGridIndex:gridIndex];

    if (index >= frcObjectCount) {
        switch (index - frcObjectCount) {
            case 0: {
                // Facebook
                if (![accountManager.facebook isSessionValid]) {
                    facebookButtonPressed = YES;
                    [accountManager authorizeFacebook];
                    [[MixpanelAPI sharedAPI] track:AnalyticsEventStartFacebookLogin properties:[NSDictionary dictionaryWithObject:@"homegrid" forKey:AnalyticsPropertySender]];                     
                } else {
                    GridDataSource *facebookDataSource = [[[FacebookGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                    [self.gridView setDataSource:facebookDataSource animated:YES];
                }
                break;
            }
            case 1: {
                // Twitter
                if ([accountManager.twitterAccountStatus integerValue]) {
                    GridDataSource *twitterDataSource = [[[TwitterGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                    [self.gridView setDataSource:twitterDataSource animated:YES];
                } else {
                    // Not logged in to Twitter
                    if (NM_RUNNING_IOS_5) {
                        [[NMAccountManager sharedAccountManager] checkAndPushTwitterAccountOnGranted:^{
                            // User should pick which Twitter account they want to log in to
                            TwitterAccountPickerViewController *picker = [[TwitterAccountPickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
                            picker.delegate = self;

                            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:picker];
                            navController.navigationBar.barStyle = UIBarStyleBlack;
                            [viewController presentModalViewController:navController animated:YES];
                            [navController release];      
                            [picker release];
                            
                            [[MixpanelAPI sharedAPI] track:AnalyticsEventStartTwitterLogin properties:[NSDictionary dictionaryWithObject:@"homegrid" forKey:AnalyticsPropertySender]]; 
                        }];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, but Twitter support requires iOS 5.0 or later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alertView show];
                        [alertView release];
                    }
                }
                break;
            }
            case 2: {
                // YouTube
                GridDataSource *youtubeDataSource = [[[YouTubeGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                [self.gridView setDataSource:youtubeDataSource animated:YES];
                break;
            }
            case 3: {
                // More
                UIViewController *youtubeViewController;
                
                if (NM_USER_YOUTUBE_SYNC_ACTIVE) {
                    // Show current YouTube sync status
                    youtubeViewController = [[YouTubeAccountStatusViewController alloc] initWithStyle:UITableViewStyleGrouped];
                } else {
                    SocialLoginViewController *socialLoginController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:nil];
                    socialLoginController.loginType = NMLoginYouTubeType;
                    youtubeViewController = socialLoginController;
                    [[MixpanelAPI sharedAPI] track:AnalyticsEventStartYouTubeLogin];
                }

                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:youtubeViewController];
                navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
                youtubeViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                                                        target:self 
                                                                                                                        action:@selector(dismissModalViewController)] autorelease];
                [viewController presentModalViewController:navigationController animated:YES];
                [youtubeViewController release];
                [navigationController release];
            }
            default:
                break;
        }
        
        return nil;
    } else {
        return [[self objectAtIndex:gridIndex] channel];
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
    index = [self mappedFetchedResultsIndexForGridIndex:index];
    return [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (NSUInteger)mappedFetchedResultsIndexForGridIndex:(NSUInteger)gridIndex
{
    return (gridIndex == 0 ? 0 : gridIndex - 1);
}

- (NSUInteger)mappedGridIndexForFetchedResultsIndex:(NSUInteger)fetchedResultsIndex;
{
    return (fetchedResultsIndex == 0 ? 0 : fetchedResultsIndex + 1);
}

- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel isUpdate:(BOOL)isUpdate
{
    cell.label.text = channel.title;
    
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
    NMVideo *latestVideo = [dataController latestVideoForChannel:channel];
    
    if (latestVideo) {
        [cell.image setImageForVideoThumbnail:latestVideo];
    } else {
        [cell.image setImageForChannel:channel];
        
        // Don't get more videos if the cell configuration is due to an update - will loop endlessly if channel has no videos
        if (!isUpdate && ![refreshingChannels containsObject:channel]) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
            [refreshingChannels addObject:channel];
        }
    }
    
    if ([refreshingChannels containsObject:channel] && !isUpdate) {
        [cell.activityIndicator startAnimating];
    } else {
        [cell.activityIndicator stopAnimating];
    }
}

- (void)refreshAllObjects
{
    for (NMSubscription *subscription in [self.fetchedResultsController fetchedObjects]) {
        NMChannel *channel = subscription.channel;
        
        if (![refreshingChannels containsObject:channel]) {
            [refreshingChannels addObject:channel];
            [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
        }
    }
}

- (void)dismissModalViewController
{
    [viewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Notifications

- (void)handleDidGetChannelVideoListNotification:(NSNotification *)notification
{
    NMChannel *channel = [[notification userInfo] objectForKey:@"channel"];
    if (channel) {
        [refreshingChannels removeObject:channel];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (facebookButtonPressed && [[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue] == NMSyncSyncInProgress) {
        // Facebook sync status updated, we have logged in successfully
        GridDataSource *facebookDataSource = [[[FacebookGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
        [self.gridView setDataSource:facebookDataSource animated:YES];
        
        facebookButtonPressed = NO;
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController 
{
    if (!self.managedObjectContext) {
        return nil;
    }
    
    if (!fetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMSubscriptionEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND channel != nil AND (channel.type == %@ OR channel.type == %@)", 
                                    [NSNumber numberWithInteger:NMChannelRecommendedType],
                                    [NSNumber numberWithInteger:NMChannelUserType]]];
        [fetchRequest setFetchBatchSize:20];

        NSSortDescriptor *sortOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
        NSSortDescriptor *recommendedFirstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"channel.type" ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:recommendedFirstDescriptor, sortOrderDescriptor, nil]];
        [sortOrderDescriptor release];
        [recommendedFirstDescriptor release];
        
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        fetchedResultsController.delegate = self;
        [fetchRequest release];
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return fetchedResultsController;
}    

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{    
    if (type == NSFetchedResultsChangeUpdate) {
        // Don't replace the cell, it messes up our drags. Just change the properties of the old one.
        NMChannel *channel = [(NMSubscription *)anObject channel];
        NSUInteger gridIndex = [self mappedGridIndexForFetchedResultsIndex:indexPath.row];
        PagingGridViewCell *cell = [self.gridView cellForIndex:gridIndex];
        [self configureCell:cell forChannel:channel isUpdate:YES];
    } else {
        [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    // +1 since first cell spans two columns, +4 for YT/FB/Twitter/More cells
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] + 5;
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    // index = 1 doesn't exist. First cell spans two columns.
    if (index == 1) return nil;
    
    PagingGridViewCell *view = (PagingGridViewCell *) [aGridView dequeueReusableCell];

    if (!view) {
        view = [[[PagingGridViewCell alloc] init] autorelease];
    }
    
    NSUInteger frcObjectCount = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    NSUInteger frcIndex = [self mappedFetchedResultsIndexForGridIndex:index];

    if (frcIndex < frcObjectCount) {
        NMSubscription *subscription = [self objectAtIndex:index];
        [self configureCell:view forChannel:subscription.channel isUpdate:NO];        
    } else {
        NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
        
        switch (frcIndex - frcObjectCount) {
            case 0: {
                if (NM_USER_FACEBOOK_CHANNEL_ID != 0) {
                    NMChannel *facebookChannel = [dataController userFacebookStreamChannel];
                    NMVideo *latestVideo = [dataController latestVideoForChannel:facebookChannel];
                    
                    if (latestVideo) {
                        view.label.text = @"Facebook";                        
                        [view.image setImageForVideoThumbnail:latestVideo];
                        view.cropsThumbnail = YES;
                    } else {
                        view.label.text = @"";                        
                        [view.image setImageDirectly:[UIImage imageNamed:@"phone_grid_item_facebook.png"]];
                        view.cropsThumbnail = NO;
                    }
                } else {
                    view.label.text = @"";                    
                    [view.image setImageDirectly:[UIImage imageNamed:@"phone_grid_item_facebook.png"]];
                    view.cropsThumbnail = NO;
                }
                break;
            }
            case 1: {
                if (NM_USER_TWITTER_CHANNEL_ID != 0) {
                    NMChannel *twitterChannel = [dataController userTwitterStreamChannel];
                    NMVideo *latestVideo = [dataController latestVideoForChannel:twitterChannel];
                    
                    if (latestVideo) {
                        view.label.text = @"Twitter";                        
                        [view.image setImageForVideoThumbnail:latestVideo];
                        view.cropsThumbnail = YES;                        
                    } else {
                        view.label.text = @"";                        
                        [view.image setImageDirectly:[UIImage imageNamed:@"phone_grid_item_twitter.png"]];  
                        view.cropsThumbnail = NO;
                    }
                } else {
                    view.label.text = @"";                    
                    [view.image setImageDirectly:[UIImage imageNamed:@"phone_grid_item_twitter.png"]];
                    view.cropsThumbnail = NO;
                }
                break;
            }                
            case 2: {
                NMChannel *youTubeChannel = [dataController userYouTubeStreamChannel];
                NMVideo *latestVideo = [dataController latestVideoForChannel:youTubeChannel];
                
                if (latestVideo) {
                    view.label.text = @"YouTube";
                    [view.image setImageForVideoThumbnail:latestVideo];
                    view.cropsThumbnail = YES;                    
                } else {
                    view.label.text = @"";
                    [view.image setImageDirectly:[UIImage imageNamed:@"phone_grid_item_youtube.png"]];
                    view.cropsThumbnail = NO;
                }
                break;
            }
            case 3:
                view.label.text = @"More";
                view.label.textColor = [UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:1.0f];
                view.label.highlightedTextColor = [UIColor colorWithRed:105.0f/255.0f green:105.0f/255.0f blue:105.0f/255.0f alpha:1.0f];
                view.label.center = CGPointMake(view.label.center.x - 12, view.label.center.y - 3);
                view.image.image = [UIImage imageNamed:@"phone_grid_item_more.png"];
                view.cropsThumbnail = NO;
                break;                
            default:
                break;
        }
    }
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    return NO;
}

- (BOOL)gridView:(PagingGridView *)gridView canRearrangeItemAtIndex:(NSUInteger)index
{
    return NO;
}

- (NSUInteger)gridView:(PagingGridView *)gridView columnSpanForCellAtIndex:(NSUInteger)index
{
    return (index == 0 ? 2 : 1);
}

#pragma mark - TwitterAccountPickerViewControllerDelegate

- (void)twitterAccountPickerViewController:(TwitterAccountPickerViewController *)twitterViewController didPickAccount:(ACAccount *)account
{    
    GridDataSource *twitterDataSource = [[[TwitterGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
    [self.gridView setDataSource:twitterDataSource animated:YES];
    
    [viewController dismissModalViewControllerAnimated:YES];
}

- (void)twitterAccountPickerViewControllerDidCancel:(TwitterAccountPickerViewController *)twitterViewController
{
    [viewController dismissModalViewControllerAnimated:YES];
}

@end
