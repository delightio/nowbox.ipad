////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AGUITableView.h
//
//  Created by Andrew Gubanov on 5/23/11.
//  Copyright 2011 Andrew Gubanov. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Imports

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Predeclarations

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Constants
enum
{
    kAGTableViewOrientationVertical = 0,
    kAGTableViewOrientationHorizontal
};
typedef NSUInteger AGTableViewOrientation;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface

@interface CategoriesOrientedTableView : UITableView <UITableViewDataSource>
{
@private
    id<UITableViewDataSource> _orientedTableViewDataSource;
    AGTableViewOrientation _tableViewOrientation;
}

@property (nonatomic, assign) AGTableViewOrientation tableViewOrientation;
@property (nonatomic, assign) id<UITableViewDataSource> orientedTableViewDataSource;

@end
