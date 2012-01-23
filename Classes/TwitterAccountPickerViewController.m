//
//  TwitterAccountPickerViewController.m
//  ipad
//
//  Created by Bill So on 1/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "TwitterAccountPickerViewController.h"
#import "NMLibrary.h"


@implementation TwitterAccountPickerViewController

@synthesize accountStore = _accountStore;
@synthesize twitterAccountArray = _twitterAccountArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[_accountStore release];
	[_twitterAccountArray release];
	[super dealloc];
}

- (void)loadTwitterAccounts {
	ACAccountType *accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	self.twitterAccountArray = [_accountStore accountsWithAccountType:accountType];
	// get which account(s) is/are selected
	
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = @"Twitter";
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountNotification:) name:ACAccountStoreDidChangeNotification object:nil];
	[self loadTwitterAccounts];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_twitterAccountArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	cell.textLabel.text = acObj.username;
    
    return cell;
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
	ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	NMTaskQueueController * tqCtrl = [NMTaskQueueController sharedTaskQueueController];
	NMChannel * chnObj = [tqCtrl.dataController insertChannelWithAccount:acObj];
	[tqCtrl issueProcessFeedForChannel:chnObj];
	//TODO: in production version, we should do the fetch after the user dismiss this view.
}

#pragma mark Notification handler

- (void)handleAccountNotification:(NSNotification *)aNotification {
	[self loadTwitterAccounts];
	[self.tableView reloadData];
}

@end
