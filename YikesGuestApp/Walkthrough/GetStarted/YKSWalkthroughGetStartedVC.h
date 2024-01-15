//
//  YKSWalkthroughGetStartedVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/12/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SCPageViewController.h"

@interface YKSWalkthroughGetStartedVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (nonatomic, assign) SCPageViewController *pvc;

- (void)refreshMissingServices;

@end
