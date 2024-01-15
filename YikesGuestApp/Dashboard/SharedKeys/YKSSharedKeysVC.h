//
//  YKSSharedKeysVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YKSDashboardCardVC;

@interface YKSSharedKeysVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UIImageView * hotelBgImageView;
@property (weak, nonatomic) IBOutlet UITableView * tableView;

@property (nonatomic, weak) YKSDashboardCardVC *dashCardVC;

@property (strong, nonatomic) YKSStayInfo * stay;

- (void)setupViewAndReloadTable;

@end
