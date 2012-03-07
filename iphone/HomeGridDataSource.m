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
#import "NMAccountManager.h"
#import "TwitterAccountPickerViewController.h"
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
    }
    return self;
}

- (void)dealloc
{    
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
                    [accountManager authorizeFacebook];
                    [[MixpanelAPI sharedAPI] track:AnalyticsEventStartFacebookLogin properties:[NSDictionary dictionaryWithObject:@"homegrid" forKey:AnalyticsPropertySender]];                     
                }
                
                GridDataSource *facebookDataSource = [[[FacebookGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                [self.gridView setDataSource:facebookDataSource animated:YES];
                break;
            }
            case 1: {
                // YouTube
                GridDataSource *youtubeDataSource = [[[YouTubeGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                [self.gridView setDataSource:youtubeDataSource animated:YES];
                break;
            }
            case 2: {
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
                            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:picker];
                            navController.navigationBar.barStyle = UIBarStyleBlack;
                            [navController setModalPresentationStyle:UIModalPresentationFormSheet];
                            picker.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSocialLogin)] autorelease];
                            
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
            default:
                break;
        }
        
        return nil;
    } else {
        return [[self objectAtIndex:gridIndex] channel];
    }
}

- (void)dismissSocialLogin
{
    [viewController dismissModalViewControllerAnimated:YES];
    
    GridDataSource *twitterDataSource = [[[TwitterGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
    [self.gridView setDataSource:twitterDataSource animated:YES];
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

#pragma mark - Notifications

- (void)handleDidGetChannelVideoListNotification:(NSNotification *)notification
{
    NMChannel *channel = [[notification userInfo] objectForKey:@"channel"];
    if (channel) {
        [refreshingChannels removeObject:channel];
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
        NSSortDescriptor *recommendedFirstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"channel.type" ascending:YES comparator:^(id type1, id type2){
            if ([type1 integerValue] == NMChannelRecommendedType) {
                return NSOrderedAscending;
            } else if ([type2 integerValue] == NMChannelRecommendedType) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
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
                view.label.text = @"Facebook";
                if (NM_USER_FACEBOOK_CHANNEL_ID != 0) {
                    NMChannel *facebookChannel = [dataController userFacebookStreamChannel];
                    [view.image setImageForVideoThumbnail:[dataController latestVideoForChannel:facebookChannel]];
                } else {
                    [view.image setImageDirectly:nil];
                }
                break;
            }
            case 1: {
                view.label.text = @"YouTube";
                NMChannel *youTubeChannel = [dataController userYouTubeStreamChannel];
                [view.image setImageForVideoThumbnail:[dataController latestVideoForChannel:youTubeChannel]];
                break;
            }
            case 2: {
                view.label.text = @"Twitter";
                if (NM_USER_TWITTER_CHANNEL_ID != 0) {
                    NMChannel *twitterChannel = [dataController userTwitterStreamChannel];
                    [view.image setImageForVideoThumbnail:[dataController latestVideoForChannel:twitterChannel]];
                } else {
                    [view.image setImageDirectly:nil];
                }
                break;
            }
            case 3:
                view.label.text = @"More";
                view.label.textColor = [UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:1.0f];
                view.label.highlightedTextColor = [UIColor colorWithRed:105.0f/255.0f green:105.0f/255.0f blue:105.0f/255.0f alpha:1.0f];
                view.label.center = CGPointMake(view.label.center.x - 6, view.label.center.y);
                view.image.image = [UIImage imageNamed:@"phone_grid_item_more.png"];
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

@end
