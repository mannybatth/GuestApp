//
//  YKSDebugConsoleTableViewController.h
//  yikes
//
//  Created by royksopp on 2015-02-03.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <stdlib.h>

#import "YikesEngineMP.h"

@class YGDashboardVC;

@interface YKSTablesConnectionsViewController : UIViewController

@property (nonatomic, strong) id delegateBLETriangle;
@property (weak, nonatomic) IBOutlet UITableView *finishedConnectionsTableView;
@property (weak, nonatomic) IBOutlet UITableView *activeConnectionsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *finishedConnectionsTableHeightConstraint;


// parent view controller
@property (nonatomic, strong) YGDashboardVC* ygDashboardVC;

// Ble triangle table view

@end
