//
//  YKSNotificationsVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 9/1/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSNotificationsVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noNotificationsLabel;

- (void)reloadTableViewAndData;

@end
