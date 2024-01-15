//
//  YKSAmenityViewController.h
//  YikesGuestApp
//
//  Created by Elliot Sinyor on 2015-07-10.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndicatorView.h"

@class YKSDashboardCardVC;

@interface YKSAmenityViewController : UIViewController

@property (weak, nonatomic) IBOutlet IndicatorView *amenitiesConnectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *amenitiesConnectionViewTopConstraint;

@property (weak) YKSDashboardCardVC * dashboardCardVC;

- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber;
- (void)handleEvent:(YKSLocationState)state;
- (void)handleAmenityDoorsUpdated:(NSArray *)newAmenities;

@end
