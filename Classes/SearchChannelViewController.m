//
//  SearchChannelViewController.m
//  ipad
//
//  Created by Tim Chen on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "SearchChannelViewController.h"
#import "CategoryTableCell.h"
#import "NMCachedImageView.h"
#import "ChannelDetailViewController.h"
#import "Analytics.h"
#import "UIView+InteractiveAnimation.h"

@implementation SearchChannelViewController

@synthesize searchBar, tableView, channelCell;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize progressView;
@synthesize noResultsView;
@synthesize lastSearchQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Search Channels";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
 	countFormatter = [[NSNumberFormatter alloc] init];
	[countFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[countFormatter setRoundingIncrement:[NSNumber numberWithInteger:1000]];
	// Do any additional setup after loading the view from its nib.
    [[searchBar.subviews objectAtIndex:0] removeFromSuperview];
    searchBar.backgroundColor = [UIColor clearColor];
    searchBar.opaque = NO;
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSearchChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidSearchNotification:) name:NMDidSearchChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailNotification:) name:NMDidFailSearchChannelsNotification object:nil];

    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
	// load the channel detail view
	channelDetailViewController = [[ChannelDetailViewController alloc] initWithNibName:@"ChannelDetailView" bundle:nil];
    channelDetailViewController.enableUnsubscribe = YES;

    [self fetchedResultsController];
    [self clearSearchResults];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.progressView = nil;
    self.noResultsView = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tableView reloadData];
    [searchBar becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
	[fetchedResultsController_ release];
 	[countFormatter release];
    [progressView release];
    [noResultsView release];
    [lastSearchQuery release];
    
	[super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImageView *theView = [[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 70, 10)] autorelease];
    theView.image = [UIImage imageNamed:@"category-list-normal-bg-turned"];
    return theView;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FindChannelCell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FindChannelTableCell" owner:self options:nil];
        cell = channelCell;
        self.channelCell = nil;
    }
    
    NMChannel * chn = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *label;
    label = (UILabel *)[cell viewWithTag:12];
    label.text = chn.title;
    
    label = (UILabel *)[cell viewWithTag:13];
	NSInteger subCount = [chn.subscriber_count integerValue];
	if ( subCount > 1000 ) {
		label.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", chn.video_count, [countFormatter stringFromNumber:chn.subscriber_count]];
	} else if ( subCount == 0 ) {
		label.text = [NSString stringWithFormat:@"%@ videos", chn.video_count];
	} else {
		label.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", chn.video_count, chn.subscriber_count];
	}
    
    UIImageView *backgroundView;
    UIButton *buttonView;
    NMCachedImageView *thumbnailView;
    
    thumbnailView = (NMCachedImageView *)[cell viewWithTag:10];
    [thumbnailView setImageForChannel:chn];
    
    buttonView = (UIButton *)[cell viewWithTag:11];
    backgroundView = (UIImageView *)[cell viewWithTag:14];
    UIImageView *newChannelIndicator = (UIImageView *)[cell viewWithTag:16];
    if ([chn.nm_subscribed boolValue]) {
        [buttonView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"] forState:UIControlStateNormal];
        [buttonView setBackgroundImage:[UIImage imageNamed:@"find-channel-subscribed-button"] forState:UIControlStateNormal];
        [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
        newChannelIndicator.hidden = ![chn.nm_is_new boolValue];
    } else {
        [buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
        [buttonView setBackgroundImage:[UIImage imageNamed:@"find-channel-not-subscribed-button"] forState:UIControlStateNormal];
        [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
        newChannelIndicator.hidden = YES;        
    }
        
    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView setAlpha:0];
    
    return cell;
    
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NMChannel * chn;
    chn = [fetchedResultsController_ objectAtIndexPath:indexPath];
    
    channelDetailViewController.channel = chn;
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventShowChannelDetails properties:[NSDictionary dictionaryWithObjectsAndKeys:chn.title, AnalyticsPropertyChannelName, 
                                                                                [NSNumber numberWithBool:NO], AnalyticsPropertySocialChannel, 
                                                                                @"search", AnalyticsPropertySender, nil]];
    
    if ([searchBar isFirstResponder]) {
        // Hide keyboard first
        [searchBar resignFirstResponder];
        [self performSelector:@selector(keyboardDidHide) withObject:nil afterDelay:0.3];
    } else {
        [self.navigationController pushViewController:channelDetailViewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)keyboardDidHide {
    [self.navigationController pushViewController:channelDetailViewController animated:YES];
}

#pragma mark Notification handlers

- (void)handleWillLoadNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleDidSearchNotification:(NSNotification *)aNotification {
//    self.searchFetchedResultsController = nil;
	NSLog(@"notification: %@", [aNotification name]);
//	// test out search predicate
//	NSFetchRequest * request = [[NSFetchRequest alloc] init];
//	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
//	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:dataCtrl.managedObjectContext]];
//	[request setPredicate:dataCtrl.searchResultsPredicate];
//	NSArray * result = [dataCtrl.managedObjectContext executeFetchRequest:request error:nil];
//	NSLog(@"search result %@", result);
//	[request release];
    
    NSString *searchText = searchBar.text;
    NSString *keyword = [[aNotification userInfo] objectForKey:@"keyword"];
    NSLog(@"got results for keyword: %@", keyword);

    if ([keyword isEqualToString:searchText]) {
        // These are the search results we're looking for
        progressView.hidden = YES;
        
        // There must be an easier way to check if the results are empty. Querying the FRC always returns 0 rows at this point.
        NSSet *channels = [NMTaskQueueController sharedTaskQueueController].dataController.internalSearchCategory.channels;
        noResultsView.hidden = ([channels count] > 1 || [[[channels anyObject] nm_id] integerValue] > 0);
        
        // Hide the keyboard, but avoid autocomplete messing with our query after it's done!
        resigningFirstResponder = YES;
        [searchBar resignFirstResponder];
        resigningFirstResponder = NO;                
        searchBar.text = searchText;
    } else {
        // These are not the search results we're looking for
        [self clearSearchResults];
    }    
}

- (void)handleDidFailNotification:(NSNotification *)aNotification {
    progressView.hidden = YES;
    noResultsView.hidden = YES;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil 
                                                        message:@"The search could not be completed. Please try again later." 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

#pragma mark Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
	
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	NSManagedObjectContext * managedObjectContext = dataCtrl.managedObjectContext;
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	//	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
	
	[fetchRequest setPredicate:dataCtrl.searchResultsPredicate];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;}


#pragma mark Fetched results controller delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }    
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[tableView endUpdates];    
}

-(void)clearSearchResults {
    NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	[ctrl.dataController clearSearchResultCache];
    self.lastSearchQuery = nil;
}

#pragma mark UIScrollViewDelegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == tableView) {
        [searchBar resignFirstResponder];
    }
}

#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [searchBar resignFirstResponder];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(performSearchWithText:) withObject:searchBar.text];
}

- (void)searchBar:(UISearchBar *)aSearchBar textDidChange:(NSString *)searchText {
    if (resigningFirstResponder) return;  // Avoid autocorrect triggering new searches
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self clearSearchResults];
    progressView.hidden = YES;
    noResultsView.hidden = YES;
    
    if ([searchText length] > 0) {
        [self performSelector:@selector(performSearchWithText:) withObject:searchText afterDelay:1.0];        
    }
}

-(IBAction)toggleChannelSubscriptionStatus:(id)sender {
    [searchBar resignFirstResponder];
    UITableViewCell *cell = (UITableViewCell *)[[sender superview] superview];
    
    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView startAnimating];
    
    UIButton *buttonView = (UIButton *)[cell viewWithTag:11];

    [UIView animateWithInteractiveDuration:0.3
                     animations:^{
                         [actView setAlpha:1];
                         [buttonView setImage:nil forState:UIControlStateNormal];                         
                     }
                     completion:^(BOOL finished) {
                     }];
    NMChannel * chn;
    chn = [fetchedResultsController_ objectAtIndexPath:[tableView indexPathForCell:cell]];
        
    BOOL subscribed = [chn.nm_subscribed boolValue];
    if (subscribed) {
        [[MixpanelAPI sharedAPI] track:AnalyticsEventUnsubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:chn.title, AnalyticsPropertyChannelName,
                                                                                    @"search_toggle", AnalyticsPropertySender, 
                                                                                    lastSearchQuery, AnalyticsPropertySearchQuery, 
                                                                                    [NSNumber numberWithBool:NO], AnalyticsPropertySocialChannel, nil]];    
    } else {
        [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:chn.title, AnalyticsPropertyChannelName,
                                                                                  @"search_toggle", AnalyticsPropertySender, 
                                                                                  lastSearchQuery, AnalyticsPropertySearchQuery, 
                                                                                  [NSNumber numberWithBool:NO], AnalyticsPropertySocialChannel, nil]];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    }
    
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:!subscribed channel:chn];
}

#pragma mark delayed search
- (void)performSearchWithText:(NSString *)searchText {
    // Don't search for the same thing twice in a row (can happen if user presses Search button)
    if ([self.lastSearchQuery isEqualToString:searchText]) return;
    
    NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
    [ctrl.dataController clearSearchResultCache];
    if ([searchText length] > 0) {
        NSLog(@"issuing search for text %@", searchText);
        progressView.hidden = NO;
        noResultsView.hidden = YES;
        [ctrl issueChannelSearchForKeyword:searchText];
        
        [[MixpanelAPI sharedAPI] track:AnalyticsEventPerformSearch properties:[NSDictionary dictionaryWithObject:searchText forKey:AnalyticsPropertySearchQuery]];
        self.lastSearchQuery = searchText;
    }
}

@end
