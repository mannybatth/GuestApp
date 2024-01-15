//
//  YKSDebugConsoleTableViewController.h
//  yikes
//
//  Created by royksopp on 2015-02-03.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class YGDashboardVC;

@interface YKSTablesConnectionsViewController : UIViewController

@property (nonatomic, strong) id delegateBLETriangle;
@property (weak, nonatomic) IBOutlet UITableView *finishedConnectionsTableView;
@property (weak, nonatomic) IBOutlet UITableView *activeConnectionsTableView;


// parent view controller
@property (nonatomic, strong) YGDashboardVC* ygDashboardVC;

// Ble triangle table view

@end
