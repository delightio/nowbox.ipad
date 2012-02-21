//
//  FeatureDebugFacebookCommentsAndLikes.m
//  ipad
//
//  Created by Bill So on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FeatureDebugFacebookCommentsAndLikes.h"


@implementation FeatureDebugFacebookCommentsAndLikes
@synthesize likesResultsController = _likesResultsController;
@synthesize commentsResultsController = _commentsResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize socialInfo = _socialInfo;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
	[_likesResultsController release];
	[_commentsResultsController release];
	[_managedObjectContext release];
	[_socialInfo release];
	[super dealloc];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	UIBarButtonItem * likeBtn = [[UIBarButtonItem alloc] initWithTitle:@"Like" style:UIBarButtonItemStyleBordered target:self action:@selector(setLikeStatus:)];
	UIBarButtonItem * unlikeBtn = [[UIBarButtonItem alloc] initWithTitle:@"Unlike" style:UIBarButtonItemStyleBordered target:self action:@selector(setUnlikeStatus:)];
	UIBarButtonItem * cmtBtn = [[UIBarButtonItem alloc] initWithTitle:@"Comment" style:UIBarButtonItemStyleBordered target:self action:@selector(sendRandomComment:)];
	self.toolbarItems = [NSArray arrayWithObjects:likeBtn, unlikeBtn, cmtBtn, nil];
	[likeBtn release];
	[cmtBtn release];
	
	self.title = _socialInfo.video.title;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	self.navigationController.toolbarHidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Target action methods
- (void)setLikeStatus:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issuePostLike:YES forPost:_socialInfo];
}

- (void)setUnlikeStatus:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issuePostLike:NO forPost:_socialInfo];
}

- (void)sendRandomComment:(id)sender {
	NSString * str = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque orci urna, iaculis lacinia ultrices vel";
	[[NMTaskQueueController sharedTaskQueueController] issuePostComment:str forPost:_socialInfo];
}

#pragma mark - Table view data source
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case 0:
		{
			NMPersonProfile * thePerson = [self.likesResultsController objectAtIndexPath:indexPath];
			cell.textLabel.text = thePerson.name;
			break;
		}
		case 1:
		{
			NMFacebookComment * theComment = [self.commentsResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
			cell.textLabel.text = theComment.message;
			break;
		}
		default:
			break;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo;
	NSFetchedResultsController * ctrl = nil;
	switch (section) {
		case 0:
			ctrl = self.likesResultsController;
			break;
		case 1:
			ctrl = self.commentsResultsController;
			break;
			
		default:
			break;
	}
	sectionInfo = [[ctrl sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	switch (indexPath.section) {
		case 0:
		{
			// like section
			NMPersonProfile * personObj = [self.likesResultsController objectAtIndexPath:indexPath];
			cell.textLabel.text = personObj.name;
			break;
		}	
		case 1:
		{
			// comment section
			NMFacebookComment * cmtObj = [self.commentsResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
			cell.textLabel.text = cmtObj.message;
			break;
		}	
		default:
			break;
	}

    [self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString * str = nil;
	switch (section) {
		case 0:
			str = @"Likes";
			break;
			
		case 1:
			str = @"Comments";
			break;
			
		default:
			break;
	}
	return str;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - Fetched results controller and delegate

- (NSFetchedResultsController *)likesResultsController {
	if ( _likesResultsController ) {
		return _likesResultsController;
	}
	
	// create the fetched resutl controller
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:NMPersonProfileEntityName inManagedObjectContext:_managedObjectContext];
	[request setEntity:entity];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[NSPredicate predicateWithFormat:@"facebookLikes CONTAINS %@", _socialInfo]];
	[request setFetchLimit:12];
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	
	NSFetchedResultsController * resultCtrl = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	resultCtrl.delegate = self;
	self.likesResultsController = resultCtrl;
	
	[resultCtrl release];
	[request release];
	NSError * error = nil;
	if ( ![_likesResultsController performFetch:&error] ) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}
	
	return _likesResultsController;
}

- (NSFetchedResultsController *)commentsResultsController {
	if ( _commentsResultsController ) {
		return _commentsResultsController;
	}
	
	// create the fetched resutl controller
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:NMFacebookCommentEntityName inManagedObjectContext:_managedObjectContext];
	[request setEntity:entity];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[NSPredicate predicateWithFormat:@"facebookInfo == %@", _socialInfo]];
	[request setFetchLimit:12];
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:NO]]];
	
	NSFetchedResultsController * resultCtrl = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	resultCtrl.delegate = self;
	self.commentsResultsController = resultCtrl;
	
	[resultCtrl release];
	[request release];
	NSError * error = nil;
	if ( ![_commentsResultsController performFetch:&error] ) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}
	
	return _commentsResultsController;
}

#pragma mark FetchedResultsController delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
	if ( controller == _commentsResultsController ) {
		// modify the index path
		newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];
		indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
	}
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
