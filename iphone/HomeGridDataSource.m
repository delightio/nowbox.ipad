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
    }
    return self;
}

- (void)dealloc
{    
    [fetchedResultsController release];
    
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
                
                self.gridView.dataSource = [[[FacebookGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];            
                break;
            }
            case 1: {
                // YouTube
                self.gridView.dataSource = [[[YouTubeGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                break;
            }
            case 2: {
                // Twitter
                if ([accountManager.twitterAccountStatus integerValue]) {
                    self.gridView.dataSource = [[[TwitterGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];                    
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
    self.gridView.dataSource = [[[TwitterGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
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
        [cell.activityIndicator stopAnimating];
    } else {
        [cell.image setImageForChannel:channel];
    
        // Don't get more videos if the cell configuration is due to an update - will loop endlessly if channel has no videos
        if (!isUpdate) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
            [cell.activityIndicator startAnimating];            
        } else {
            [cell.activityIndicator stopAnimating];
        }    
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
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [sortDescriptor release];
        
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
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] + 4;
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
        switch (frcIndex - frcObjectCount) {
            case 0:
                view.label.text = @"Facebook";
                view.image.image = [UIImage imageNamed:@"social-facebook.png"];
                break;
            case 1:
                view.label.text = @"YouTube";
                view.image.image = [UIImage imageNamed:@"social-youtube.png"];
                break;
            case 2:
                view.label.text = @"Twitter";
                view.image.image = [UIImage imageNamed:@"social-twitter.png"];            
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
