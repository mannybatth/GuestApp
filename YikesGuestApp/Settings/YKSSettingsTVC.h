//
//  YKSSettingsTVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/11/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSSettingsTVC : YKSBaseTVC

@property (weak, nonatomic) IBOutlet UILabel *versionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *envLabelSettings;
@property (weak, nonatomic) IBOutlet UILabel *debugNotificationsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *debugNotificationsSwitch;


@end
