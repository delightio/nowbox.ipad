//
//  VideoRowController.m
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "VideoRowController.h"


@implementation VideoRowController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize videoTableView;

- (id)initWithFrame:(CGRect)aframe {
	self = [super init];
	videoTableView	= [[EasyTableView alloc] initWithFrame:aframe numberOfColumns:100 ofWidth:98.0f];
	
	videoTableView.delegate					= self;
//	videoTableView.tableView.backgroundColor	= ;
	videoTableView.tableView.allowsSelection	= YES;
//	videoTableView.tableView.separatorColor	= [[UIColor blackColor] colorWithAlphaComponent:0.1];
//	videoTableView.cellBackgroundColor		= [[UIColor blackColor] colorWithAlphaComponent:0.1];
	videoTableView.autoresizingMask			= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	return self;
}

- (void)dealloc {
	[videoTableView release];
	[fetchedResultsController_ release];
	[managedObjectContext_ release];
	[super dealloc];
}

#pragma mark -
#pragma mark EasyTableViewDelegate

// These delegate methods support both example views - first delegate method creates the necessary views

- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {
	CGRect labelRect		= CGRectMake(10, 10, rect.size.width-20, rect.size.height-20);
	UILabel *label			= [[[UILabel alloc] initWithFrame:labelRect] autorelease];
	label.textAlignment		= UITextAlignmentCenter;
	label.textColor			= [UIColor whiteColor];
	label.font				= [UIFont boldSystemFontOfSize:60];
	
	// Use a different color for the two different examples
	label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
	
//	UIImageView *borderView		= [[UIImageView alloc] initWithFrame:label.bounds];
//	borderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//	borderView.tag				= BORDER_VIEW_TAG;
//	
//	[label addSubview:borderView];
//	[borderView release];
	
	return label;
}

// Second delegate populates the views with data from a data source

- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndex:(NSUInteger)index {
	UILabel *label	= (UILabel *)view;
	label.text		= [NSString stringWithFormat:@"%i", index];
	
	// selectedIndexPath can be nil so we need to test for that condition
//	BOOL isSelected = (easyTableView.selectedIndexPath) ? (easyTableView.selectedIndexPath.row == index) : NO;
//	[self borderIsSelected:isSelected forView:view];		
}

// Optional - Tracks the selection of a particular cell

- (void)easyTableView:(EasyTableView *)easyTableView selectedView:(UIView *)selectedView atIndex:(NSUInteger)index deselectedView:(UIView *)deselectedView {
//	[self borderIsSelected:YES forView:selectedView];		
//	
//	if (deselectedView) 
//		[self borderIsSelected:NO forView:deselectedView];
//	
//	UILabel *label	= (UILabel *)selectedView;
//	bigLabel.text	= label.text;
}


@end
