//
//  ChannelManagementViewController.m
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelManagementViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CategoriesOrientedTableView.h"
#import "CategoryCellView.h"
#import "CategoryTableCell.h"
#import "NMCachedImageView.h"
#import "SearchChannelViewController.h"
#import "ChannelDetailViewController.h"
#import "SocialLoginViewController.h"

NSString * const NMChannelManagementWillAppearNotification = @"NMChannelManagementWillAppearNotification";
NSString * const NMChannelManagementDidDisappearNotification = @"NMChannelManagementDidDisappearNotification";


@implementation ChannelManagementViewController
@synthesize categoriesTableView;
@synthesize channelsTableView;
@synthesize activityIndicator;
@synthesize categoryFetchedResultsController;
@synthesize myChannelsFetchedResultsController;
@synthesize selectedIndexPath;
@synthesize selectedIndexPathForTable;
@synthesize selectedChannelArray;
@synthesize managedObjectContext;
@synthesize containerView;
@synthesize channelCell;
@synthesize sectionTitleBackgroundImage;
@synthesize sectionTitleColor;
@synthesize sectionTitleFont;

- (void)dealloc {
	[channelDetailViewController release];
    [myChannelsFetchedResultsController release];
    [categoriesTableView release];
    [channelsTableView release];
    [activityIndicator release];
	[selectedChannelArray release];
	[categoryFetchedResultsController release];
	[managedObjectContext release];
	[selectedIndexPath release];
    [selectedIndexPathForTable release];
	[sectionTitleBackgroundImage release];
	[sectionTitleColor release];
	[sectionTitleFont release];
	[countFormatter release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	nowboxTaskController = [NMTaskQueueController sharedTaskQueueController];
	styleUtility = [NMStyleUtility sharedStyleUtility];
	countFormatter = [[NSNumberFormatter alloc] init];
	[countFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[countFormatter setRoundingIncrement:[NSNumber numberWithInteger:1000]];
	
	self.title = @"Channel Management";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchView:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissView:)] autorelease]; 
	
    containerView.layer.cornerRadius = 4;

    [categoriesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [channelsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [categoriesTableView setFrame:CGRectMake(0, 0, 70, 530)];
    categoriesTableView.orientedTableViewDataSource = self;
    categoriesTableView.tableViewOrientation = kAGTableViewOrientationHorizontal;
    [categoriesTableView setAlwaysBounceVertical:YES];
//    [categoriesTableView setShowsVerticalScrollIndicator:NO];
    
    categoriesTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"category-list-normal-bg-turned"]];

	// load the channel detail view
	channelDetailViewController = [[ChannelDetailViewController alloc] initWithNibName:@"ChannelDetailView" bundle:nil];
	self.sectionTitleBackgroundImage = [UIImage imageNamed:@"channel-title-background"];
	self.sectionTitleColor = [UIColor colorWithRed:190.0f / 255.0f green:148.0f / 255.0f blue:39.0f / 255.0f alpha:1.0f];
	self.sectionTitleFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11.0f];

    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    [categoriesTableView selectRowAtIndexPath:indexPath animated:NO  scrollPosition:UITableViewScrollPositionNone];
    [[categoriesTableView delegate] tableView:categoriesTableView didSelectRowAtIndexPath:indexPath];
	
}

- (void)viewDidUnload
{
    [self setCategoriesTableView:nil];
    [self setChannelsTableView:nil];
    self.activityIndicator = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];
		// all subsequent transition happened in navigation controller should not fire channel management notification
		viewPushedByNavigationController = YES;
	}
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelsForCategoryNotification:) name:NMDidGetChannelsForCategoryNotification object:nil];
    
//    [nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSubscribeChannelNotification object:nil];
//	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillUnsubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
    
    [channelsTableView reloadData];
    
    [categoriesTableView flashScrollIndicators];

}

-(void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementDidDisappearNotification object:self];
		[nowboxTaskController.dataController clearChannelCache];
	}
}

#pragma mark Notification handlers

- (void)handleDidGetChannelsForCategoryNotification:(NSNotification *)aNotification {
	if ( selectedIndexPath ) {
		NMCategory * cat = [[aNotification userInfo] objectForKey:@"category"];
		NMCategory * selCat = [categoryFetchedResultsController objectAtIndexPath:selectedIndexPath];
		if ( selCat == cat ) {
			// same category. relaod data
			NSSet * chnSet = cat.channels;
			self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
			[channelsTableView reloadData];
		}
	}
    
    [activityIndicator stopAnimating];
}

//- (void)handleWillLoadNotification:(NSNotification *)aNotification {
////	NSLog(@"notification: %@", [aNotification name]);
//}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
    NMChannel * channel = [userInfo objectForKey:@"channel"];
    
    if (selectedIndex == 0) {
        // Reload social channels in case we unsubscribed from one of them
        [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];            
        [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];            
    }
    
    for (int i=0; i<[selectedChannelArray count]; i++) {
        NMChannel * chn = [selectedChannelArray objectAtIndex:i];
        if (chn == channel) {
            [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark Target-action methods

- (void)showSearchView:(id)sender {
	SearchChannelViewController * vc = [[SearchChannelViewController alloc] init];
    [vc clearSearchResults];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
//	TwitterLoginViewController * twitCtrl = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
//	[self.navigationController pushViewController:twitCtrl animated:YES];
//	[twitCtrl release];
}

- (void)dismissView:(id)sender {
    NSInteger subscribedCount = [[[self.myChannelsFetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    if (subscribedCount == 0) {
        // Don't allow user to dismiss view if not subscribed to any channels
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"You have unsubscribed all your channels." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    } else {    
        viewPushedByNavigationController = NO;
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ( tableView == categoriesTableView || selectedIndex ) return 1;
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSUInteger c = 0;
	id <NSFetchedResultsSectionInfo> sectionInfo;
	if ( tableView == categoriesTableView ) {
		sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:section];
		c = (([sectionInfo numberOfObjects]+1)*2)-1;
	} else {
		// the real list of subscribed channels
		if ( selectedIndex == 0 ) {
			switch (section) {
				case 0:
					// social login
					c = 2;
					break;
					
				case 1:
					sectionInfo = [[self.myChannelsFetchedResultsController sections] objectAtIndex:0];
					c = [sectionInfo numberOfObjects];
					break;
					
				default:
					break;
			}
		} else {
			c = [selectedChannelArray count];
		}
	}
	return c;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ( tableView == categoriesTableView || selectedIndex ) return 0.0f;
    return 29.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ( tableView == categoriesTableView || selectedIndex ) return nil;
	UIView * ctnView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 29.0f)];
	ctnView.layer.contents = (id)sectionTitleBackgroundImage.CGImage;
	ctnView.backgroundColor = styleUtility.clearColor;
	
	UILabel * lbl = [[UILabel alloc] initWithFrame:CGRectMake(18.0f, 0.0f, 10.0f, 29.0f)];
	[ctnView addSubview:lbl];
	lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	lbl.backgroundColor = styleUtility.clearColor;
	lbl.font = sectionTitleFont;
	lbl.textColor = sectionTitleColor;
	lbl.shadowColor = [UIColor whiteColor];
	lbl.shadowOffset = CGSizeMake(0.0f, 1.0f);
	
	switch (section) {
		case 0:
			lbl.text = @"SOCIAL CHANNELS";
			
			break;
			
		case 1:
			lbl.text = @"SUBSCRIBED CHANNELS";
			break;
			
		default:
			break;
	}
	[lbl release];
	return [ctnView autorelease];
//	return  [lbl autorelease];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell.
	if ( aTableView == categoriesTableView ) {
        static NSString *CellIdentifier = @"CategoryCell";
		
        CategoryTableCell *categtoryCell = (CategoryTableCell *)[categoriesTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (categtoryCell == nil) {
            categtoryCell = [[[CategoryTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        [categtoryCell setHighlighted:NO];
        [categtoryCell setSelected:(selectedIndexPathForTable.row == indexPath.row)];
        
        if (indexPath.row == 0) { // my channels
            [categtoryCell setCategoryTitle:nil];
            [categtoryCell setUserInteractionEnabled:YES];
        } else if (indexPath.row % 2 == 0) { // other categories
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            [categtoryCell setCategoryTitle:cat.title];
            [categtoryCell setUserInteractionEnabled:YES];
        }
        else { // separator
            if (([indexPath row] == selectedIndex+1) || ([indexPath row] == selectedIndex-1)) {
                [categtoryCell setCategoryTitle:@""];
            } else {
                [categtoryCell setCategoryTitle:@"<SEPARATOR>"];
            }
            [categtoryCell setUserInteractionEnabled:NO];
        }
        
        return categtoryCell;
        
	} else {
		
        static NSString *CellIdentifier = @"FindChannelCell";
        
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"FindChannelTableCell" owner:self options:nil];
            cell = channelCell;
            self.channelCell = nil;
        }
		
		NMCachedImageView *thumbnailView;
		NMChannel * chn;
        UIImageView *backgroundView;
        UIButton *buttonView;
		
		if ( selectedIndex == 0 && indexPath.section == 0 ) {
			// the social login
			UILabel * titleLbl, * detailLbl;
			titleLbl = (UILabel *)[cell viewWithTag:12];
			detailLbl = (UILabel *)[cell viewWithTag:13];
			thumbnailView = (NMCachedImageView *)[cell viewWithTag:10];
            buttonView = (UIButton *)[cell viewWithTag:11];
            backgroundView = (UIImageView *)[cell viewWithTag:14];        

			switch (indexPath.row) {
				case 0:
					if ( NM_USER_TWITTER_CHANNEL_ID ) {
						chn = nowboxTaskController.dataController.userTwitterStreamChannel;
						titleLbl.text = chn.title;
						detailLbl.text = [NSString stringWithFormat:@"%@ videos", chn.video_count];

						[thumbnailView setImageForChannel:chn];
						if ([chn.nm_subscribed boolValue]) {
							[buttonView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"] forState:UIControlStateNormal];
							[backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
						} else {
							[buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
							[backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
						}
					} else {
						titleLbl.text = @"Twitter";
						detailLbl.text = @"Sign in to watch videos in your Twitter network";
						thumbnailView.image = [UIImage imageNamed:@"social-twitter"];
                        [buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
                        [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];                        
					}
					break;
					
				case 1:
					if ( NM_USER_FACEBOOK_CHANNEL_ID ) {
						chn = nowboxTaskController.dataController.userFacebookStreamChannel;
						titleLbl.text = chn.title;
						detailLbl.text = [NSString stringWithFormat:@"%@ videos", chn.video_count];
						[thumbnailView setImageForChannel:chn];
						buttonView = (UIButton *)[cell viewWithTag:11];
						backgroundView = (UIImageView *)[cell viewWithTag:14];
						if ([chn.nm_subscribed boolValue]) {
							[buttonView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"] forState:UIControlStateNormal];
							[backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
						} else {
							[buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
							[backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
						}
					} else {
						titleLbl.text = @"Facebook";
						detailLbl.text = @"Sign in to watch videos in your Facebook network";
						thumbnailView.image = [UIImage imageNamed:@"social-facebook"];
                        [buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
                        [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];                                                
					}
					break;
					
				default:
					break;
			}
            
            UIActivityIndicatorView *actView;
            actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
            [actView setAlpha:0];
            [buttonView setAlpha:1];
            
			return cell;
		}
		indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        if (selectedIndex == 0) {
            chn = [myChannelsFetchedResultsController objectAtIndexPath:indexPath];
        } else {
            chn = [selectedChannelArray objectAtIndex:indexPath.row];
        }

        thumbnailView = (NMCachedImageView *)[cell viewWithTag:10];
        [thumbnailView setImageForChannel:chn];
        
        buttonView = (UIButton *)[cell viewWithTag:11];
        backgroundView = (UIImageView *)[cell viewWithTag:14];
        if ([chn.nm_subscribed boolValue]) {
            [buttonView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"] forState:UIControlStateNormal];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
        } else {
            [buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
        }
        
        UILabel *label;
        label = (UILabel *)[cell viewWithTag:12];
        label.text = chn.title;
        
        label = (UILabel *)[cell viewWithTag:13];
		// round the subscribers count to nearest thousand, don't if not subscribers
		NSInteger subCount = [chn.subscriber_count integerValue];
		if ( subCount > 1000 ) {
			label.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", chn.video_count, [countFormatter stringFromNumber:chn.subscriber_count]];
		} else if ( subCount == 0 ) {
			label.text = [NSString stringWithFormat:@"%@ videos", chn.video_count];
		} else {
			label.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", chn.video_count, chn.subscriber_count];
		}
        
        UIActivityIndicatorView *actView;
        actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
        [actView setAlpha:0];
        [buttonView setAlpha:1];
      
        return cell;
	}
    
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( tableView == categoriesTableView ) {
        if (indexPath.row == 0) { // my channels
            return 80;
        } else if (indexPath.row % 2 == 0) { // other categories
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            return [self categoryCellWidthFromString:cat.title];
        }
        else { // separator
            return 2;
        }
    } else {
        return 65;
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [activityIndicator stopAnimating];
    
	if ( tableView == categoriesTableView ) {
        // deselect first
        
        if (selectedIndex - 1 > 0) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex-1 inSection:0]] setCategoryTitle:@"<SEPARATOR>"];
        }
        if (selectedIndex + 1 < [tableView numberOfRowsInSection:0]) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex+1 inSection:0]] setCategoryTitle:@"<SEPARATOR>"];
        }
        if (indexPath.row - 1 > 0) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]] setCategoryTitle:@""];
        }
        if (indexPath.row + 1 < [tableView numberOfRowsInSection:0]) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]] setCategoryTitle:@""];
        }
        
        // Handle selection manually to keep previous selection on highlight
        CategoryTableCell *selectedCell = (CategoryTableCell *)[tableView cellForRowAtIndexPath:indexPath];
        CategoryTableCell *previousSelectedCell = (CategoryTableCell *)[tableView cellForRowAtIndexPath:selectedIndexPathForTable];

        [previousSelectedCell setSelected:NO];
        [selectedCell setSelected:YES];
        self.selectedIndexPathForTable = indexPath;

        [lockToEdgeCell removeFromSuperview]; lockToEdgeCell = nil; 

        // Scroll the cell to be visible
        if (selectedCell.frame.origin.y - tableView.contentOffset.y < 0) {
            enableLockToEdge = NO;
            [tableView setContentOffset:CGPointMake(0, selectedCell.frame.origin.y) animated:YES];
        } else if (selectedCell.frame.origin.y + selectedCell.frame.size.height - tableView.contentOffset.y > tableView.frame.size.width) {
            enableLockToEdge = NO;
            [tableView setContentOffset:CGPointMake(0, (selectedCell.frame.origin.y + selectedCell.frame.size.height) - tableView.frame.size.width) animated:YES];            
        }
        
        selectedIndex = indexPath.row;

        if (indexPath.row == 0) { // my channels
            self.selectedIndexPath = nil;
            self.selectedChannelArray = nil;
            [channelsTableView reloadData];
            return;
        } else if (indexPath.row % 2 == 0) { // other categories
            // refresh the right table data
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            self.selectedIndexPath = indexPath;
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            NSSet * chnSet = cat.channels;
            self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
            [channelsTableView reloadData];
            
			// use this count check as criteria to fetch channel list from server
			if ( [cat.nm_last_refresh timeIntervalSinceNow] < 60.0f ) {
				// fetch if last fetch happens 1 min ago. The "last refresh" value will get reset when  channel management view is dismissed.
                [nowboxTaskController issueGetChannelsForCategory:cat];
                
                if ([selectedChannelArray count] == 0) {
                    [activityIndicator startAnimating];
                }
			}
            return;
        } else { // separator
            return;
        }
	} else {
        NMChannel * chn = nil;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if ( selectedIndex == 0 ) {
            if ( indexPath.section == 0 ) {
                // reveal the social login view
                SocialLoginViewController * socialCtrl;
                if ( indexPath.row == 0 ) {
                    if ( NM_USER_TWITTER_CHANNEL_ID ) {
                        chn = nowboxTaskController.dataController.userTwitterStreamChannel;
                    } else {
                        // login twitter
                        socialCtrl = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:nil];
                        socialCtrl.loginType = LoginTwitterType;
                        [self.navigationController pushViewController:socialCtrl animated:YES];
                        [socialCtrl release];
                        
                        return;
                    }
                } else if ( indexPath.row == 1 ) {
                    if ( NM_USER_FACEBOOK_CHANNEL_ID ) {
                        chn = nowboxTaskController.dataController.userFacebookStreamChannel;
                    } else {
                        socialCtrl = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:nil];
                        socialCtrl.loginType = LoginFacebookType;
                        [self.navigationController pushViewController:socialCtrl animated:YES];
                        [socialCtrl release];
                        
                        return;
                    }
                }
            } else {
                indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
                chn = [myChannelsFetchedResultsController objectAtIndexPath:indexPath];
            }
        } else {
            chn = [selectedChannelArray objectAtIndex:indexPath.row];
        }
		channelDetailViewController.channel = chn;
		[self.navigationController pushViewController:channelDetailViewController animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == categoriesTableView && enableLockToEdge) {
        /* Keeps selected category on left or right edge */
        CategoryTableCell *selectedCell = (CategoryTableCell *)[categoriesTableView cellForRowAtIndexPath:selectedIndexPathForTable];
        BOOL lockToEdge = NO;
        CGFloat edgePosition;
        
        if (![selectedCell superview]) {
            // Cell has been removed when offscreen, its superview is nil. Its frame is no longer valid, but find the locked position based on the previous locked position.
            lockToEdge = YES;
            if (lockToEdgeCell.frame.origin.y - categoriesTableView.contentOffset.y < categoriesTableView.frame.size.width / 2) {
                edgePosition = 0;
            } else {
                edgePosition = categoriesTableView.frame.size.width - lockToEdgeCell.frame.size.height;
            }
            
        } else if (selectedCell.frame.origin.y - categoriesTableView.contentOffset.y < 0) {
            // Lock to left edge
            lockToEdge = YES;
            edgePosition = 0;
        } else if (selectedCell.frame.origin.y + selectedCell.frame.size.height - categoriesTableView.contentOffset.y > categoriesTableView.frame.size.width) {
            // Lock to right edge
            lockToEdge = YES;
            edgePosition = categoriesTableView.frame.size.width - selectedCell.frame.size.height;            
        } else {  
            // Don't lock to edge
            [lockToEdgeCell removeFromSuperview]; lockToEdgeCell = nil;  
        }

        if (lockToEdge) {            
            if (!lockToEdgeCell) {
                // Clone the cell and add it to the tableview
                lockToEdgeCell = [selectedCell copy];
                lockToEdgeCell.tag = selectedIndexPathForTable.row;
                lockToEdgeCell.transform = CGAffineTransformMakeRotation(M_PI/2.0);
                lockToEdgeCell.frame = selectedCell.frame;
                lockToEdgeCell.selectedBackgroundView.hidden = YES;
                
                [lockToEdgeCell setSelected:YES];
                [categoriesTableView addSubview:lockToEdgeCell];
                [lockToEdgeCell release];                 
            }
            
            // Keep the cloned cell from moving
            CGRect frame = lockToEdgeCell.frame;
            frame.origin.y = edgePosition + categoriesTableView.contentOffset.y;
            lockToEdgeCell.frame = frame;
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    enableLockToEdge = YES;
}

#pragma mark Fetched results controller
- (NSFetchedResultsController *)categoryFetchedResultsController {
    if (categoryFetchedResultsController != nil) {
        return categoryFetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
		
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // search results is a category but with -1 as ID, ignore that
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_id > 0"]];

    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.categoryFetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![categoryFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return categoryFetchedResultsController;
}


- (NSFetchedResultsController *)myChannelsFetchedResultsController {
    
    if (myChannelsFetchedResultsController != nil) {
        return myChannelsFetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	//	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
	
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND NOT type IN %@", [NSSet setWithObjects:[NSNumber numberWithInteger:NMChannelUserFacebookType], [NSNumber numberWithInteger:NMChannelUserTwitterType], [NSNumber numberWithInteger:NMChannelUserType], nil]]];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.myChannelsFetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![myChannelsFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return myChannelsFetchedResultsController;
}    



#pragma mark Fetched results controller delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (controller == categoryFetchedResultsController) {
        [categoriesTableView beginUpdates];
    }
    else {
        if (selectedIndex == 0) {
            [channelsTableView beginUpdates];
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (controller == categoryFetchedResultsController) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [categoriesTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [categoriesTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
    else {
        if (selectedIndex == 0) {
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [channelsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [channelsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    if (controller == categoryFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row*2+1 inSection:indexPath.section];
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
//                [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
                
            case NSFetchedResultsChangeDelete:
//                [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [categoriesTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[indexPath row] inSection:[indexPath section]]] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
//                [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
        }
    }
    else {
        if (selectedIndex == 0) {
            // Map section 0 in core data to section 1 in table
            newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];
            indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
            
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [channelsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [channelsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeUpdate:
                    [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeMove:
                    [channelsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [channelsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (controller == categoryFetchedResultsController) {
        [categoriesTableView endUpdates];
    }
    else {
        if (selectedIndex == 0) {
            [channelsTableView endUpdates];
        }
    }
}

#pragma mark helpers
-(float)categoryCellWidthFromString:(NSString *)text {
    if (text == nil) {
        return 38;
    }
    else {
        CGSize textLabelSize;
        if ( NM_RUNNING_IOS_5 ) {
            textLabelSize = [[text uppercaseString] sizeWithFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16]];
        }
        else {
            textLabelSize = [[text uppercaseString] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
        }
        return textLabelSize.width+40;
    }
    return 0;
}

#pragma mark UIAlertView delegates
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        UIActivityIndicatorView *actView;
        actView = (UIActivityIndicatorView *)[cellToUnsubscribeFrom viewWithTag:15];
        [actView startAnimating];
        
        UIButton *buttonView = (UIButton *)[cellToUnsubscribeFrom viewWithTag:11];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             [actView setAlpha:1];
                             [buttonView setAlpha:0];
                         }
                         completion:^(BOOL finished) {
                         }];
        
        [nowboxTaskController issueSubscribe:![channelToUnsubscribeFrom.nm_subscribed boolValue] channel:channelToUnsubscribeFrom];
    }
}
 
-(IBAction)toggleChannelSubscriptionStatus:(id)sender {
    UITableViewCell *cell = (UITableViewCell *)[[sender superview] superview];
    NSIndexPath *tableIndexPath = [channelsTableView indexPathForCell:cell];

    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView startAnimating];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [actView setAlpha:1];
                         [sender setAlpha:0];
                     }
                     completion:^(BOOL finished) {
                     }];
    NMChannel * chn;
    if (selectedIndex == 0) {
        if (tableIndexPath.section == 0) {
            // Social channels
            if (tableIndexPath.row == 0) {
                if ( NM_USER_TWITTER_CHANNEL_ID ) {
                    chn = nowboxTaskController.dataController.userTwitterStreamChannel;
                } else {
                    [self tableView:channelsTableView didSelectRowAtIndexPath:tableIndexPath];
                    return;
                }
            } else {
                if ( NM_USER_FACEBOOK_CHANNEL_ID ) {
                    chn = nowboxTaskController.dataController.userFacebookStreamChannel;
                } else {
                    [self tableView:channelsTableView didSelectRowAtIndexPath:tableIndexPath];
                    return;
                }                
            }
        } else {
            NSIndexPath *fetchedIndexPath = [NSIndexPath indexPathForRow:tableIndexPath.row 
                                                               inSection:0];
            chn = [myChannelsFetchedResultsController objectAtIndexPath:fetchedIndexPath];
        }
    } else {
        chn = [selectedChannelArray objectAtIndex:[channelsTableView indexPathForCell:cell].row];
    }
    
    [nowboxTaskController issueSubscribe:![chn.nm_subscribed boolValue] channel:chn];
    
}

@end
