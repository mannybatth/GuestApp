//
//  YKSSideBarVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/9/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSSideBarVC : UITableViewController

@property (weak, nonatomic) IBOutlet UIView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *userInitialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@end
