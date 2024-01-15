//
//  YKSAppDelegate.m
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAppDelegate.h"
#import "YKSPasscodeScreenVC.h"
#import "YKSWalkthroughNC.h"
#import "YKSWalkthroughVC.h"
#import "YKSTestAccounts.h"
#import "YKSDashboardNC.h"
#import "YKSDashboardVC.h"
#import "PKAlertYikesTheme.h"

@import SafariServices;

@import YikesGenericEngine;

@interface YKSAppDelegate () <YKSPasscodeScreenVCDelegate, YikesEngineDelegate>

@property (nonatomic, strong) NSMutableSet *engineObservers;

@property (nonatomic, strong) UIAlertController *ios10_0_usersAlert;
@property (nonatomic, strong, readonly) NSString *ios10_0_alertTitle;

@property (nonatomic, strong, readonly) NSString *ios10_0_usersLastNotifiedKey;
@property (nonatomic, strong, readonly) NSString *ios10_0_usersLastWarnedKey;

@end

@implementation YKSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _ios10_0_alertTitle = @"Important Message to iOS 10.0 users";
    _ios10_0_usersLastNotifiedKey = @"ios_10_0_alertLastNotifiedKey";
    _ios10_0_usersLastWarnedKey = @"ios10_0_usersLastWarnedKey";
    
    [Fabric with:@[CrashlyticsKit]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLockoutDidEnd:) name:kApplicationLockoutDidEndNotification object:nil];
    
    [AppManager sharedInstance];
    
    self.engineObservers = [NSMutableSet set];
    [YikesEngine initEngineWithDelegate:self];

    YKSUserInfo *userInfo = [YikesEngine sharedInstance].userInfo;
    BOOL userAcceptedEULA = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"EULAacceptedAlready_userid%@", userInfo.userId]];
    
    if (userInfo) {
        
        // Fabric & Crashlytics stuff:
        [[AppManager sharedInstance] setFabricUserInfo];
        
        CLS_LOG(@"Already logged in, redirect to view after login");
        
        if (userAcceptedEULA) {
            
            if ([YKSPasscodeScreenVC isPasscodeSet]) {
                YikesApplication.isLocked = YES;
            }
            
            [[YikesEngine sharedEngine] userAcceptedEULA:userInfo.email];
            [self goToViewAfterLogin];
            [self showLockScreenIfPasscodeSet];
            
        } else {
            
            // Login screen should then redirect to EULA screen
            [self goToLoginView];
        }
    
    } else {
        
        CLS_LOG(@"Not logged in, stopping engine, redirect to login");
        
        // Stop engine if it was ON
        if ([YikesEngine sharedInstance].engineState != kYKSEngineStateOff) {
            [[YikesEngine sharedInstance] stopEngineWithSuccess:nil];
        }
        
        BOOL walkthroughPlayedAlready = [[NSUserDefaults standardUserDefaults] boolForKey:@"WalkthroughPlayedAlready"];
        if (!walkthroughPlayedAlready) {
            [self goToWalkthrough];
        } else {
            [self goToLoginView];
        }
    }
    
    [PKAlertThemeManager setRegisterDefaultTheme:[[PKAlertYikesTheme alloc] init]];
    
    //Set default error image
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"ic_error_outline_36pt"]];

    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:16.0]
                                                           }
                                                forState:UIControlStateNormal];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.ios10_0_usersLastWarnedKey];
    [self saveUserDefaults];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    
    // ex: https://dev-api.yikes.co/ycentral/default/user/verify_email/36476287-eaec-4507-99b9-a05ad38c2159
    
    if (userActivity.webpageURL) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Link detected" message:userActivity.webpageURL.absoluteString preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    
    return YES;
}

- (void)goToWalkthrough {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Walkthrough" bundle:nil];
    UINavigationController * walkthroughNC = [sb instantiateViewControllerWithIdentifier:@"YKSWalkthroughNC"];
    self.window.rootViewController = walkthroughNC;
    
}

- (void)presentWalkthroughOverViewController:(UIViewController *)viewController {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Walkthrough" bundle:nil];
    UINavigationController * walkthroughNC = [sb instantiateViewControllerWithIdentifier:@"YKSWalkthroughNC"];
    [viewController presentViewController:walkthroughNC animated:NO completion:nil];
    
}

- (void)goToLoginView {
    
    YikesApplication.isLocked = NO;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UINavigationController * loginNC = [sb instantiateInitialViewController];
    self.window.rootViewController = loginNC;
}

- (void)goToViewAfterLogin {
    
    YKSUserInfo *user = [[YikesEngine sharedInstance] userInfo];
    
    // Redirect to login view if no user is found
    if (!user) {
        [self goToLoginView];
        return;
    }
    
    [[YikesEngine sharedInstance] resumeEngine];
    
    if ([YKSTestAccounts isTestUser:[[YikesEngine sharedInstance] userInfo].email]) {
        [[YikesEngine sharedInstance] setDebugMode:YES];
        [[YikesEngine sharedInstance] handleDebugToolsLogin];
    } else {
        [[YikesEngine sharedInstance] setDebugMode:NO];
    }
    
    UIStoryboard *app = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MMDrawerController *drawerVC = [app instantiateInitialViewController];
    
    drawerVC.leftDrawerViewController = [app instantiateViewControllerWithIdentifier:@"YKSSideBarVC"];
    drawerVC.centerViewController = [app instantiateViewControllerWithIdentifier:@"YKSDashboardNC"];
    
    drawerVC.showsShadow = YES;
    [drawerVC setOpenDrawerGestureModeMask:(MMOpenDrawerGestureModeBezelPanningCenterView | MMOpenDrawerGestureModePanningNavigationBar)];
    [drawerVC setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [drawerVC setDrawerVisualStateBlock:[MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:4]];
    
    self.window.rootViewController = drawerVC;
    
    [[AppManager sharedInstance] registerForPushNotifications];
    [[YikesEngine sharedInstance] requestLocationAlwaysAuthorization];
}

- (void)applicationDidTimeout:(NSNotification *)notification {
    [self showLockScreenIfPasscodeSet];
}

- (void)applicationLockoutDidEnd:(NSNotification *)notification {
    
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[YKSPasscodeScreenVC class]]) {
        YKSPasscodeScreenVC *passcodeScreenVC = (YKSPasscodeScreenVC *)self.window.rootViewController.presentedViewController;
        [passcodeScreenVC endLockout];
    }
}

- (void)showLockScreenIfPasscodeSet {
    
    if (![YKSPasscodeScreenVC isPasscodeSet] || ![[YikesEngine sharedInstance] userInfo] ) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.window.rootViewController.presentedViewController isKindOfClass:[PKAlertViewController class]]) {
            [self.window.rootViewController.presentedViewController dismissViewControllerAnimated:YES completion:^{
                [self presentPasscodeUnlockScreen];
            }];
            return;
        }
        [self presentPasscodeUnlockScreen];
        
    });
}

- (void)presentPasscodeUnlockScreen {
    
    YikesApplication.isLocked = YES;
    
    //TODO: The passcode screen VC should have a unique reference in the AppManager or any object that is not part of the UI
    // so it's possible to only have 1 instance and the presentation can be tracked easily for dismissal etc.
    
    UIViewController *topVC = self.window.rootViewController;
    DLog(@"topVC is %@", topVC);
    
//    MMDrawerController
    
    if (![topVC.presentedViewController isKindOfClass:[YKSPasscodeScreenVC class]]) {
        
        if ([topVC isKindOfClass:[MMDrawerController class]]) {
            MMDrawerController *mmDC = (id)topVC;
            UINavigationController *centerNC = (id)(mmDC.centerViewController);
            UIViewController *topNCVC = centerNC ? centerNC.topViewController : nil;
            if (topNCVC == nil || ![topNCVC.presentedViewController isKindOfClass:[YKSPasscodeScreenVC class]]) {
                YKSPasscodeScreenVC *passcodeScreenVC = [YKSPasscodeScreenVC passcodeScreenWithMode:kYKSPasscodeViewModeUnlock];
                passcodeScreenVC.delegate = self;
                UIViewController *presentedVC = topNCVC ? topNCVC.presentedViewController : nil;
                if (presentedVC) {
                    
                    // can't present from a presented VC - it will throw a warning "Attempt to present <> on <> which is already presenting"
                    if (presentedVC.presentedViewController) {
                        DLog(@"Dismissing another presenterVC: %@", presentedVC.presentedViewController);\
                        [presentedVC.presentedViewController dismissViewControllerAnimated:NO completion:^{
                            DLog(@"");
                        }];
                    }
                    [presentedVC dismissViewControllerAnimated:NO completion:^{
                        [passcodeScreenVC presentOverViewController:self.window.rootViewController];
                    }];
                }
                else {
                    UIViewController *rootVC = self.window.rootViewController;
                    if (rootVC.presentedViewController) {
                        [rootVC dismissViewControllerAnimated:YES completion:^{
                            [passcodeScreenVC presentOverViewController:rootVC];
                        }];
                    }
                    else {
                        [passcodeScreenVC presentOverViewController:self.window.rootViewController];
                    }
                }
            }
        }
    }
}

- (void)unlockWasSuccessfulForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
    YikesApplication.isLocked = NO;
    [passcodeScreenVC dismiss];
    [YikesApplication resetIdleTimer];
}

- (void)unlockWasUnsuccessfulForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    YikesApplication.isBackgrounded = YES;
    
    // Help users see the important message about the iOS 10.0 critical bug w/ Bluetooth:
    if ([YikesApplication runsOniOS10_0_X]) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.ios10_0_usersLastWarnedKey];
        [self saveUserDefaults];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    if ([self shouldWarniOS10_0_users]) {
        [self presentiOS10_0_warning];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.ios10_0_usersLastWarnedKey];
        [self saveUserDefaults];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    YikesApplication.isBackgrounded = NO;
    
    [self warniOS10_0_usersIfRequired];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.ios10_0_usersLastWarnedKey];
    [self saveUserDefaults];
}

- (void)addEngineObserver:(NSObject *)object {
    
    if (![self.engineObservers containsObject:object]) {
        [self.engineObservers addObject:object];
    }
}

- (void)removeEngineObserver:(NSObject *)object {
    
    if ([self.engineObservers containsObject:object]) {
        [self.engineObservers removeObject:object];
    }
}

#pragma mark - YikesEngineDelegate Delegate methods

- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineUserInfoDidUpdate:)]) {
            [observer yikesEngineUserInfoDidUpdate:yikesUser];
        }
    }];
}

- (void)yikesEngineStateDidChange:(YKSEngineState)state {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineStateDidChange:)]) {
            [observer yikesEngineStateDidChange:state];
        }
    }];
    
    if (state == kYKSEngineStateOff) {
        // reset local notification fireDate on logout:
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.ios10_0_usersLastNotifiedKey];
        [self saveUserDefaults];
    }
    
    else if (state == kYKSEngineStateOn || state == kYKSEngineStatePaused) {
        [self warniOS10_0_usersIfRequired];
    }
}

- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineRoomConnectionStatusDidChange:withRoom:)]) {
            [observer yikesEngineRoomConnectionStatusDidChange:newStatus withRoom:room];
        }
    }];
}

- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room disconnectReasonCode:(YKSDisconnectReasonCode)code {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineRoomConnectionStatusDidChange:withRoom:disconnectReasonCode:)]) {
            [observer yikesEngineRoomConnectionStatusDidChange:newStatus withRoom:room disconnectReasonCode:code];
        }
    }];
}

- (void)yikesEngineLocationStateDidChange:(YKSLocationState)state {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineLocationStateDidChange:)]) {
            [observer yikesEngineLocationStateDidChange:state];
        }
    }];
    
    [self warniOS10_0_usersIfRequired];
}

- (void)yikesEngineDeviceMotionStateDidChange:(YKSDeviceMotionState)state {
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineDeviceMotionStateDidChange:)]) {
            [observer yikesEngineDeviceMotionStateDidChange:state];
        }
    }];
}

- (void)yikesEngineRequiredServicesMissing:(NSSet *)missingServices {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    if (user.stays && user.stays.count > 0) {
        if ([missingServices containsObject:@(kYKSBluetoothService)]) {
            [AppDelegate showBluetoothIsDisabledLocalNotification];
        }
        
        if ([missingServices containsObject:@(kYKSInternetConnectionService)]) {
            [AppDelegate showNoInternetConnectionLocalNotification];
        }
    }
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineRequiredServicesMissing:)]) {
            [observer yikesEngineRequiredServicesMissing:missingServices];
        }
    }];
}

- (void)yikesEngineErrorDidOccur:(YKSError *)yikesError {
    
    if (yikesError.reportOnCrashlytics) {
        NSDictionary *debugInformation = [[YikesEngine sharedInstance] debugInformation];
        [CrashlyticsKit recordError:yikesError.nsError withAdditionalUserInfo:debugInformation];
        [[YikesEngine sharedInstance] logMessage:[NSString stringWithFormat:@"Recorded error %@ on CLS with debug information:\n%@", yikesError, debugInformation]];
        return;
    }
    
    if (yikesError.logEventOnCrashlytics) {
        NSDictionary *debugInformation = [[YikesEngine sharedInstance] debugInformation];
        NSDictionary *customAttributes = yikesError.eventCustomAttributes;
        if (!customAttributes && debugInformation) {
            customAttributes = debugInformation;
        }
        if (!customAttributes) {
            customAttributes = [NSDictionary dictionary];
        }
        [Answers logCustomEventWithName:yikesError.eventName customAttributes:customAttributes];
        [[YikesEngine sharedInstance] logMessage:[NSString stringWithFormat:@"Logged Event with name %@, error %@ on CLS with debug information:\n%@", yikesError.eventName ? yikesError.eventName : yikesError.nsError.domain.description, yikesError, debugInformation ? debugInformation : @""]];
        return;
    }
    
    if (yikesError.errorCode == kYKSInvalidCredentials) {
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        
        NSString *title = @"Password required";
        NSString *message = @"The password is not valid anymore.\nPlease enter your new password to continue.";
        
        if (state == UIApplicationStateBackground) {
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody = message;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = 1;
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
        else {
            
            if ([self.window.rootViewController isKindOfClass:[MMDrawerController class]]) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
                        
                        configuration.title = title;
                        configuration.message = message;
                        configuration.presentationTransitionStyle = PKAlertControllerPresentationTransitionStyleFocusIn;
                        
                        NSMutableArray *actions = [NSMutableArray array];
                        [actions addObject:[PKAlertAction okAction]];
                        [configuration addActions:actions];
                        
                    }];
                    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                });
            }
        }
        
        [self goToLoginView];
        return;
    }
    
    [self.engineObservers enumerateObjectsUsingBlock:^(NSObject<YikesEngineDelegate> * _Nonnull observer, BOOL * _Nonnull stop) {
        
        if ([observer respondsToSelector:@selector(yikesEngineErrorDidOccur:)]) {
            [observer yikesEngineErrorDidOccur:yikesError];
        }
    }];
}

#pragma mark - iOS 10.0 users warning

- (BOOL)shouldWarniOS10_0_users {
    BOOL shouldWarn = [YikesApplication runsOniOS10_0_X] && (![self isPresentingiOS10_0_usersAlert]);
    
    // check further:
    if (shouldWarn) {
        // Avoid notifying too frequently - once per hour max:
        NSDate *lastWarned = [[NSUserDefaults standardUserDefaults] objectForKey:self.ios10_0_usersLastWarnedKey];
        if (lastWarned) {
            // It was fired on lastFired date
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastWarned];
            if (interval < 60*60*1) {
                shouldWarn = NO;
            }
        }
    }
    return shouldWarn;
}

- (BOOL)isPresentingiOS10_0_usersAlert {
    id presentedVC = [self.window.rootViewController presentedViewController];
    if (presentedVC != nil && ([presentedVC isEqual:self.ios10_0_usersAlert] || [presentedVC isKindOfClass:[SFSafariViewController class]])) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)presentiOS10_0_warning {
    
    self.ios10_0_usersAlert = [UIAlertController alertControllerWithTitle:
                                @"Important Message to\niOS 10.0 users" message:
                                @"Your device is likely to have issues unlocking doors due to a known bug with Bluetooth in iOS 10.0.\nApple has fixed the issue in iOS 10.1 and is working on a release.\nUntil then we have some options\nto help:"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self.ios10_0_usersAlert addAction:[UIAlertAction actionWithTitle:@"Later" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
    [self.ios10_0_usersAlert addAction:[UIAlertAction actionWithTitle:@"See Options" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SFSafariViewController *sf = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://yikes.co/ios-10-bug-update/"]];
        [sf setPreferredBarTintColor:[UIColor yikesBlack]];
        [self.window.rootViewController presentViewController:sf animated:YES completion:^{}];
    }]];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:self.ios10_0_usersLastWarnedKey];
    [self saveUserDefaults];
    
    [self.window.rootViewController presentViewController:self.ios10_0_usersAlert animated:YES completion:^{}];
}

- (void)warniOS10_0_usersIfRequired {
    
    if (![YikesApplication runsOniOS10_0_X]) {
        return;
    }
    
    BOOL backgrounded = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
    BOOL shouldFire = YES;
    if (backgrounded) {
        // Avoid notifying too frequently - once per day max:
        NSDate *lastFired = [[NSUserDefaults standardUserDefaults] objectForKey:self.ios10_0_usersLastNotifiedKey];
        if (lastFired) {
            // It was fired on lastFired date
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastFired];
            if (interval < 60*60*24) {
                shouldFire = NO;
            }
        }
        if (shouldFire) {
            [self fireiOS10_0_notification];
        }
    }
    else if ([self shouldWarniOS10_0_users]) {
        [self presentiOS10_0_warning];
    }
}

- (void)fireiOS10_0_notification {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self fireLocalNotification:@"Read our message about a bug in iOS 10.0 that can prevent your device from unlocking doors." title:self.ios10_0_alertTitle];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:self.ios10_0_usersLastNotifiedKey];
        [self saveUserDefaults];
    }
}

- (void)saveUserDefaults {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - App Local Notifications

- (void)showBluetoothIsDisabledLocalNotification {
    
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"bluetoothIsDisabledNotificationDate"];
    NSDate *now = [NSDate date];
    
    if (lastDate) {
        NSTimeInterval timeDifference = [now timeIntervalSinceDate:lastDate];
        if (timeDifference < 3*60*60) { // 3 hours
            return;
        }
    }
    
    [self fireLocalNotification:@"Bluetooth must be turned on for yikes mobile key to work. Turn on Bluetooth from your device's Settings and go to the app."];
    
    [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"bluetoothIsDisabledNotificationDate"];
    [self saveUserDefaults];
}

- (void)showNoInternetConnectionLocalNotification {
    
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"noInternetConnectionNotificationDate"];
    NSDate *now = [NSDate date];
    
    if (lastDate) {
        NSTimeInterval timeDifference = [now timeIntervalSinceDate:lastDate];
        if (timeDifference < 3*60*60) { // 3 hours
            return;
        }
    }
    
    [self fireLocalNotification:@"No internet connection. Please check your settings to continue using mobile key."];
    
    [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"noInternetConnectionNotificationDate"];
    [self saveUserDefaults];
}

- (void)fireLocalNotification:(NSString *)message title:(NSString *)title {
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif) {
        localNotif.alertBody = [NSString stringWithFormat:@"%@", message];
        localNotif.alertAction = NSLocalizedString(@"Relaunch", @"Relaunch");
        localNotif.soundName = UILocalNotificationDefaultSoundName;
        if (title) {
            localNotif.alertTitle = title;
        }
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
    }
    
}

- (void)fireLocalNotification:(NSString *)message {
    [self fireLocalNotification:message title:nil];
}

- (void)fireDebugLocalNotification:(NSString *)message {
#ifdef PUSH
    BOOL showDebugNotifications = YES;
    if (showDebugNotifications) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = [NSString stringWithFormat:@"%@", message];
            localNotif.alertAction = NSLocalizedString(@"Relaunch", @"Relaunch");
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
    }
#endif
}

#pragma mark - PubNub / push notification delegate

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    [[YikesEngine sharedInstance] logMessage:@"[PN] didRegisterUserNotificationSettings - registering for remote notifications..."];
    //register to receive notifications
    [application registerForRemoteNotifications];
}

// #3 add delegate to get the deviceToken from the APNs callback didRegisterForRemoteNotificationsWithDeviceToken
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {

    self.pushDeviceToken = deviceToken;
    
    [self fireDebugLocalNotification:[NSString stringWithFormat:@"Device token is:\n%@", deviceToken]];
    [[YikesEngine sharedInstance] logMessage:@"[PN] Did register for Remote Notifications, now setting up PubNub..."];
    
    // This will device whether it should register or unregister on PubNub based on the user session state:
    [[AppManager sharedInstance] configureAndStartPubNub];
    
    // Refresh tableview if we are on the walkthrough
    if ([self.window.rootViewController isKindOfClass:[YKSWalkthroughNC class]]) {
        
        YKSWalkthroughNC *walkthroughNC = (YKSWalkthroughNC *)self.window.rootViewController;
        if ([walkthroughNC.topViewController isKindOfClass:[YKSWalkthroughVC class]]) {
            
            YKSWalkthroughVC *walkthroughVC = (YKSWalkthroughVC *)walkthroughNC.topViewController;
            [walkthroughVC refreshGetStartedMissingServices];
        }
        
    } else if ([self.window.rootViewController isKindOfClass:[MMDrawerController class]]) {
        
        MMDrawerController *mmDC = (MMDrawerController *)self.window.rootViewController;
        
        if ([mmDC.centerViewController isKindOfClass:[YKSDashboardNC class]]) {
            
            YKSDashboardNC *dashNC = (YKSDashboardNC *)mmDC.centerViewController;
            if ([dashNC.topViewController isKindOfClass:[YKSDashboardVC class]]) {
                
                YKSDashboardVC *dashVC = (YKSDashboardVC *)dashNC.topViewController;
                [dashVC reloadMissingServices];
            }
        }
    }
}

// #4 add delegate to report any errors getting the deviceToken (optional)
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    // Let the engine know about this failure:
    [[YikesEngine sharedInstance] logMessage:[NSString stringWithFormat:@"[PN] didFailToRegisterForRemoteNotificationsWithError: %@", error]];
    NSLog(@"DELEGATE: Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[YikesEngine sharedEngine] handlePushNotificationMessage:nil completionHandler:completionHandler];
    [self warniOS10_0_usersIfRequired];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if ([notification.alertTitle isEqualToString:self.ios10_0_alertTitle]) {
        if ([self shouldWarniOS10_0_users]) {
            [self presentiOS10_0_warning];
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    [[YikesEngine sharedEngine] setBackgroundCompletionHandler:completionHandler];
}


@end
