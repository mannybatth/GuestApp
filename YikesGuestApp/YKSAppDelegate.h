//
//  AppDelegate.h
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import PKAlertController;
@import SVProgressHUD;
@import Fabric;
@import Crashlytics;
@import YikesSharedModel;
@import MMDrawerController;


@interface YKSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property NSData *pushDeviceToken;

- (void)goToWalkthrough;
- (void)presentWalkthroughOverViewController:(UIViewController *)viewController;
- (void)goToLoginView;
- (void)goToViewAfterLogin;

- (void)showBluetoothIsDisabledLocalNotification;
- (void)fireLocalNotification:(NSString *)message;
- (void)fireDebugLocalNotification:(NSString *)message;

- (void)addEngineObserver:(NSObject *)object;
- (void)removeEngineObserver:(NSObject *)object;

@end

