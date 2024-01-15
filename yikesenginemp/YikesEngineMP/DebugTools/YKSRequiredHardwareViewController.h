//
//  YKSRequiredHardwareViewController.h
//  yikes
//
//  Created by royksopp on 2015-05-13.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSRequiredHardwareViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *missingRequiredHardwareTableView;
@property (weak, nonatomic) IBOutlet UIButton *openSettingsButton;

@end
