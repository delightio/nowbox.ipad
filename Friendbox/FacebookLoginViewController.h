//
//  FacebookLoginViewController.h
//  ipad
//
//  Created by Chris Haugli on 3/30/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FacebookLoginViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton *connectFacebookButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)loginToFacebook:(id)sender;

@end
