//
//  YouTubeAccountStatusViewController.m
//  ipad
//
//  Created by Bill So on 11/11/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "YouTubeAccountStatusViewController.h"
#import "NMLibrary.h"
#import "ipadAppDelegate.h"


@implementation YouTubeAccountStatusViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"YouTube";
		logoutButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		logoutButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[logoutButton setTitle:@"Logout Account" forState:UIControlStateNormal];
		[logoutButton addTarget:self action:@selector(logoutUser:) forControlEvents:UIControlEventTouchUpInside];
		logoutButton.frame = CGRectMake(30.0f, 20.0f, 260.0f, 45.0f);
		UIImage * btnBgImage = [UIImage imageNamed:@"button-logout-background"];
		[logoutButton setBackgroundImage:[btnBgImage stretchableImageWithLeftCapWidth:16 topCapHeight:0] forState:UIControlStateNormal];
		[logoutButton.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]];
		logoutButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[logoutButton release];
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

	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDeauthNotification:) name:NMDidDeauthorizeUserNotification object:nil];
	[nc addObserver:self selector:@selector(handleFailDeauthNotification:) name:NMDidFailDeauthorizeUserNotification object:nil];

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
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 65.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView * ctnView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 45.0f)];
	ctnView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[ctnView addSubview:logoutButton];
	return [ctnView autorelease];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
	switch (indexPath.row) {
		case 0:
			// cell
			cell.textLabel.text = @"Account";
			cell.detailTextLabel.text = NM_USER_YOUTUBE_USER_NAME;
			break;
			
		case 1:
			// cell
			cell.textLabel.text = @"Sync Status";
			cell.detailTextLabel.text = @"Active";
			break;
			
		case 2:
		{
			cell.textLabel.text = @"Last Sync";
			NSDateFormatter * fmt = [[NSDateFormatter alloc] init];
			[fmt setDateStyle:NSDateFormatterShortStyle];
			[fmt setTimeStyle:NSDateFormatterShortStyle];
            
            if (NM_USER_YOUTUBE_LAST_SYNC > 0) {
                cell.detailTextLabel.text = [fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)NM_USER_YOUTUBE_LAST_SYNC]];
            } else {
                cell.detailTextLabel.text = @"Synchronizing";
            }
			break;
		}	
		default:
			break;
	}
    
	
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

#pragma mark - Notification handler
- (void)handleDeauthNotification:(NSNotification *)aNotification {
	[self.navigationController popViewControllerAnimated:YES];
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs setBool:NM_USER_YOUTUBE_SYNC_ACTIVE forKey:NM_USER_YOUTUBE_SYNC_ACTIVE_KEY];
	[defs setObject:NM_USER_YOUTUBE_USER_NAME forKey:NM_USER_YOUTUBE_USER_NAME_KEY];
}

- (void)handleFailDeauthNotification:(NSNotification *)aNotification {
	logoutButton.enabled = YES;
}

#pragma mark - Target-action methods
- (void)logoutUser:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueDeauthorizeYouTube];
	logoutButton.enabled = NO;
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
//}

@end
