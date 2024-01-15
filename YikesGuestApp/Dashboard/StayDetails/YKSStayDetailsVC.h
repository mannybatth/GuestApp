//
//  YKSStayDetailsVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/21/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HexColors;

@interface YKSStayDetailsVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) YKSStayInfo *stay;

@end
