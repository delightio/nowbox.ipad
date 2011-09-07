//
//  PreviewViewContainerView.h
//  ipad
//
//  Created by Tim Chen on 4/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewContainerView : UIView {
    IBOutlet UIScrollView *scrollView;
}

@property (nonatomic,retain) UIScrollView *scrollView;

@end
