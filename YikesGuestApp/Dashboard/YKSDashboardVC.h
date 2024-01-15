//
//  YKSDashboardVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HexColors;

@interface YKSDashboardVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UIView * missingServicesButtonContainerView;
@property (weak, nonatomic) IBOutlet UIImageView * missingServicesIcon;
@property (weak, nonatomic) IBOutlet UIButton * missingServicesButton;

- (void)reloadMissingServices;

@end
