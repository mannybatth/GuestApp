//
//  YKSDashboardCardOptionsVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HexColors;

@class YKSDashboardCardVC;

@interface YKSDashboardCardOptionsVC : UIViewController

@property (strong, nonatomic) YKSStayInfo * stay;

@property (nonatomic) BOOL sharedKeysButtonSelected;

@property (weak, nonatomic) IBOutlet UIButton * callHotelButton;
@property (weak, nonatomic) IBOutlet UIButton * directionButton;
@property (weak, nonatomic) IBOutlet UIButton * sharedKeysButton;
@property (weak, nonatomic) IBOutlet UIButton * weatherButton;
@property (weak, nonatomic) IBOutlet UIButton * stayDetailsButton;

@property (nonatomic, weak) YKSDashboardCardVC *dashCardVC;

- (void)updateSharedKeysCountBadge;

@end
