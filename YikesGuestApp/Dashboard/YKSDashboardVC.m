//
//  YKSDashboardVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSDashboardVC.h"
#import "YKSDashboardNC.h"
#import "AppManager.h"
#import "YKSDashboardCardVC.h"
#import "YKSNoStaysVC.h"
#import "YKSNotificationsNC.h"
#import "YKSNotificationsVC.h"
#import "YKSSharedKeysVC.h"
#import "YKSTestAccounts.h"

#import "SCPageViewController.h"
#import "SCScrollView.h"
#import "SCEasingFunction.h"

#import "SCParallaxPageLayouter.h"
#import "M13BadgeView.h"

#import "YKSAppDelegate.h"

//#define TESTING 1

@interface YKSDashboardVC () <YikesEngineDelegate, SCPageViewControllerDataSource, SCPageViewControllerDelegate, YKSDashboardCardVCDelegate>

@property (nonatomic, strong) NSArray *stays;
@property (nonatomic, strong) SCPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableDictionary *cards;

@property (nonatomic, strong) NSSet *missingServices;
@property (nonatomic, strong) MissingDeviceRequirementsVC *missingDeviceRequirementsVC;
@property (nonatomic) BOOL showMissingServicesAlertOnLoad;

@property (nonatomic, strong) M13BadgeView *notificationsBadge;
@property (strong, nonatomic) M13BadgeView *missingServicesBadge;

@property (strong, nonatomic) UnlockDoorTipPresentationController * unlockDoorTipPresentationController;

@end

@implementation YKSDashboardVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.cards = [NSMutableDictionary dictionary];
    
    self.showMissingServicesAlertOnLoad = NO;
    
    self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
    
    [self.pageViewController setLayouter:[[SCParallaxPageLayouter alloc] init] animated:NO completion:nil];
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    [self.pageViewController setContinuousNavigationEnabled:NO];
    
    [self addChildViewController:self.pageViewController];
    [self.pageViewController.view setFrame:self.view.bounds];
    [self.view insertSubview:self.pageViewController.view atIndex:0];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.pageViewController.scrollView.bounces = NO;
    
    self.notificationsBadge = [[M13BadgeView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    [self.notificationsBadge setFont:[UIFont fontWithName:@"HelveticaNeue" size:10.0]];
    [self.notificationsBadge setBadgeBackgroundColor:[UIColor colorWithHexString:@"5F9318"]];
    [self.notificationsBadge setShadowBadge:NO];
    [self.notificationsBadge setMinimumWidth:18.0f];
    [self.notificationsBadge setAlignmentShift:CGSizeMake(-11.0f, 8.0f)];
    [self.notificationsBadge setHidesWhenZero:YES];
    [[self.navigationItem.rightBarButtonItem valueForKey:@"view"] addSubview:self.notificationsBadge];
    
    self.missingServicesBadge = [[M13BadgeView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
    [self.missingServicesBadge setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0]];
    [self.missingServicesBadge setBadgeBackgroundColor:[UIColor colorWithHexString:@"5F9318"]];
    [self.missingServicesBadge setShadowBadge:NO];
    [self.missingServicesBadge setHidesWhenZero:YES];
    [self.missingServicesBadge setAlignmentShift:CGSizeMake(-5.0f, 8.0f)];
    [self.missingServicesIcon addSubview:self.missingServicesBadge];
    
    self.missingServicesButtonContainerView.layer.cornerRadius = 16.0f;
    self.missingServicesButtonContainerView.clipsToBounds = YES;
    
    if (self.missingServices.count > 0) {
        [self resumeMissingServicesButtonPulse];
    }
    
    [self reloadMissingServices];
    
    self.unlockDoorTipPresentationController = [[UnlockDoorTipPresentationController alloc] initWithParent:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [AppDelegate addEngineObserver:self];
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    
#ifdef DEBUG
//    [self startSimulatingDoorConnections];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    [AppDelegate removeEngineObserver:self];
}

- (void)dealloc {
    
    NSArray *controllers = [self.pageViewController loadedViewControllers];
    
    for (id cardVC in controllers) {
        
        if ([cardVC isKindOfClass:[YKSDashboardCardVC class]]) {
            YKSDashboardCardVC *card = (YKSDashboardCardVC *)cardVC;
            
            [card stopStayStatusUpdateTimer];
            [card stopCheckinCheckoutLabelTimer];
        }
    }
    
    [self.cards removeAllObjects];
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    self.pageViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)reloadMissingServices {
    
    [[YikesEngine sharedEngine] missingServices:^(NSSet *missingServices) {
        [self yikesEngineRequiredServicesMissing:missingServices];
    }];
    
}

- (IBAction)hamburgerMenuButtonTapped:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)notificationBellButtonTapped:(id)sender {
    [(YKSDashboardNC *)self.navigationController toggleNotificationsView:sender];
}

- (void)setupView {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    self.stays = user.stays;
    
    if (!self.stays ||
        self.stays.count == 0) {
        
        UIStoryboard *app = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        YKSNoStaysVC *noStaysVC = [app instantiateViewControllerWithIdentifier:@"YKSNoStaysVC"];
        [self.navigationController pushViewController:noStaysVC animated:NO];
        
        return;
    }
    
    // sort by arrival date
    NSArray *sortedStays;
    sortedStays = [self.stays sortedArrayUsingComparator:^NSComparisonResult(YKSStayInfo *stayOne, YKSStayInfo *stayTwo) {
        NSDate *firstArrivalDate = [[YKSDateHelper sharedInstance] setDate:stayOne.arrivalDate withTimeString:stayOne.checkInTime andTimeZone:stayOne.hotelTimezone];
        NSDate *secondArrivalDate = [[YKSDateHelper sharedInstance] setDate:stayTwo.arrivalDate withTimeString:stayTwo.checkInTime andTimeZone:stayTwo.hotelTimezone];
        return [firstArrivalDate compare:secondArrivalDate];
    }];
    self.stays = sortedStays;
    
    [self.pageViewController reloadData];
    [self yikesEngineRequiredServicesMissing:self.missingServices];
    
    [self updateNotificationsBadge];
}

- (void)updateNotificationsBadge {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    NSUInteger notificationsCount = 0;
    for (YKSStayShareInfo *stayShare in user.stayShares) {
        if ([stayShare.secondaryGuest.userId isEqualToNumber:user.userId] &&
            [stayShare.status isEqualToString:@"pending"]) {
            
            notificationsCount++;
        }
    }
    
    self.notificationsBadge.text = [NSString stringWithFormat:@"%li", (long)notificationsCount];
}

- (IBAction)viewSwiped:(id)sender {
    
    if ([YKSTestAccounts isTestUser:[[YikesEngine sharedEngine] userInfo].email]) {
        [[YikesEngine sharedEngine] setDebugMode:YES];
        [[YikesEngine sharedEngine] showDebugViewInView:self.view];
    }
    
}

- (NSArray *)temp_userStays {
    
    NSMutableArray *temp_stays = [NSMutableArray array];
    NSUInteger numberOfStays = 5;
    for (int i = 0; i < numberOfStays; i++) {
        
        NSDictionary *dict = @{
                               @"check_in_time": @"09:00:00",
                               @"check_out_time": @"10:00:00",
                               @"arrival_date": @"2015-06-16",
                               @"depart_date": @"2015-06-17",
                               @"room_number": @"1004",
                               @"number_of_nights": @"30",
                               @"hotel": @{
                                       @"name": @"yikesDev"
                                       },
                               @"amenities": @[
                                       @{
                                           @"name" : @"Gym"
                                           },
                                       @{
                                           @"name" : @"Pool"
                                           }
                                   ]
                               };
        
        YKSStayInfo *stay = [YKSStayInfo newWithJSONDictionary:dict];
        [temp_stays addObject:stay];
        
    }
    
    return temp_stays;
}

#pragma mark - Simulations
- (void)startSimulatingDoorConnections {
    __block YKSDisconnectReasonCode disconnectReason = 1;
    NSString *room = @"205";
    NSTimeInterval interval = 2;
    
    // first case:
    [self simulateConnectionToRoom:room thenDisconnectWithReason:disconnectReason interval:interval];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self simulateConnectionToRoom:room thenDisconnectWithReason:kYKSDisconnectReasonCodeExpired interval:interval];
//    });
    [self simulateNextCase:disconnectReason+1 forRoom:room interval:interval];
}

- (void)simulateNextCase:(YKSDisconnectReasonCode)disconnectReason forRoom:(NSString*)room interval:(NSTimeInterval)interval {
    __block YKSDisconnectReasonCode reason = disconnectReason;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Simulate the 2 cases that have UI feedback:
        // start
        if (reason == kYKSDisconnectReasonCodeExpired) {
            reason = kYKSDisconnectReasonCodeProximity;
        }
        else {
            reason = kYKSDisconnectReasonCodeExpired;
        }
        // end
        
        [self simulateConnectionToRoom:room thenDisconnectWithReason:disconnectReason interval:interval];
        
        // to go through each status, uncomment this:
        // start
//        reason += 1;
//        if (reason > kYKSDisconnectReasonCodeSuperseded) {
//            reason = 1;
//        }
        // end
        
        [self simulateNextCase:reason forRoom:room interval:interval];
    });
}



- (void)simulateConnectionToRoom:(NSString *)room thenDisconnectWithReason:(YKSDisconnectReasonCode)disconnectReason interval:(NSTimeInterval)interval {
    [self simulateConnectedToRoom:room];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self simulateDisconnectedFromRoom:room reason:disconnectReason];
    });
}

- (void)simulateConnectedToRoom:(NSString *)room {
    [self yikesEngineRoomConnectionStatusDidChange:kYKSConnectionStatusConnectedToDoor withRoom:room];
}

- (void)simulateDisconnectedFromRoom:(NSString *)room reason:(YKSDisconnectReasonCode)reason {
    [self yikesEngineRoomConnectionStatusDidChange:kYKSConnectionStatusDisconnectedFromDoor withRoom:room disconnectReasonCode:reason];
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController {
    
#ifdef TESTING
    return [self temp_userStays].count;
#else
    return self.stays.count;
#endif
    
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController
            viewControllerForPageAtIndex:(NSUInteger)pageIndex {

#ifdef TESTING
    NSArray *stays = [self temp_userStays];
#else
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    self.stays = user.stays;
#endif
    
    YKSStayInfo *stay = [self.stays objectAtIndex:pageIndex];
    
    YKSDashboardCardVC *card;
    
    if ([self.cards objectForKey:@(pageIndex)]) {
        
        card = [self.cards objectForKey:@(pageIndex)];
        
        if (card.roomNumberLabel.text != nil) {
            if (stay.roomNumber == nil) {
                [card handleRoomEvent:kYKSConnectionStatusDisconnectedFromDoor forRoomNumber:card.roomNumberLabel.text];
            }
        }
        
    } else {
        
        UIStoryboard *app = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        card = [app instantiateViewControllerWithIdentifier:@"YKSDashboardCardVC"];
        [self.cards setObject:card forKey:@(pageIndex)];
        
        card.delegate = self;
        
    }
    
    card.stay = stay;
    card.cardIndex = pageIndex;
    card.totalNumOfCards = self.stays.count;
    [card.amenityVC handleAmenityDoorsUpdated:stay.amenities];
    
    return card;
}

- (void)updateCardTitlesOpacity {
    
    [self.cards enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, YKSDashboardCardVC *card, BOOL *stop) {
        
        if ([card isEqual:[NSNull null]]) {
            return;
        }
        
        CGFloat percentageVisible = [self.pageViewController visiblePercentageForViewController:card];
        
        CGFloat speed = 1.5;
        CGFloat calculatedAlpha = 1.0-((1.0-percentageVisible)*speed);
        CGFloat alpha = MIN(1.0, calculatedAlpha);
        if (alpha == -0.5) alpha = 1.0;
        
        [card.hotelTitleLabel setAlpha:alpha];
        
    }];
    
}

- (PKAlertViewController *)alertForMissingServices:(NSSet *)missingServices {
    
    // Missing services alert
    return [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
        
        configuration.title = @"Missing device requirements";
        
        NSString *message = @"";
        NSUInteger index = 0;
        
        for (NSNumber *serviceNum in missingServices) {
            
            YKSServiceType service = (YKSServiceType)[serviceNum integerValue];
            switch (service) {
                case kYKSBluetoothService:
                    message = [message stringByAppendingString:@"Need bluetooth enabled"];
                    break;
                case kYKSLocationService:
                    message = [message stringByAppendingString:@"Need location services enabled"];
                    break;
                case kYKSInternetConnectionService:
                    message = [message stringByAppendingString:@"Need internet connection"];
                    break;
                case kYKSPushNotificationService:
                    message = [message stringByAppendingString:@"Need push notifications"];
                    break;
                case kYKSBackgroundAppRefreshService:
                    message = [message stringByAppendingString:@"Need background app refresh enabled"];
                    break;
                    
                default:
                    break;
            }
            
            index++;
            
            if (index < missingServices.count) {
                message = [message stringByAppendingString:@"\n"];
            }
        }
        
        configuration.message = message;
        
        [configuration addAction:[PKAlertAction actionWithTitle:@"Ignore" handler:^(PKAlertAction *action, BOOL closed) {
            
        }]];
        
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
            [configuration addAction:[PKAlertAction actionWithTitle:@"yikes Settings" handler:^(PKAlertAction *action, BOOL closed) {
                
                if (closed) {
                    [[UIApplication sharedApplication] openURL:settingsURL];
                }
                
            }]];
        }
        
    }];
}

- (IBAction)missingServicesButtonTouched:(id)sender {
    
    [self showMissingServicesAlert];
}

- (void)startMissingServicesButtonPulseWithCount:(NSInteger)count {
    
    [self resumeMissingServicesButtonPulse];
    self.missingServicesButtonContainerView.hidden = NO;
}

- (void)stopMissingServicesButtonPulse {
    
    [self stopPulsingAnimationForView:self.missingServicesIcon];
    self.missingServicesButtonContainerView.hidden = YES;
}

- (void)resumeMissingServicesButtonPulse {
    
    if (self.missingServices.count > 0) {
        self.missingServicesBadge.text = [NSString stringWithFormat:@"%li", (long)self.missingServices.count];
        [self startPulsingAnimationForView:self.missingServicesIcon];
    }
}

- (void)startPulsingAnimationForView:(UIView *)view {
    
    view.hidden = NO;
    if (![view.layer animationForKey:@"opacity"]) {
        [view setAlpha:0.2f];
        
        [UIView animateWithDuration:1.0f
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                         animations:^{
                             [view setAlpha:1.0f];
                         }
                         completion:nil];
    }
}

- (void)stopPulsingAnimationForView:(UIView *)view {
    [view.layer removeAllAnimations];
    view.hidden = YES;
}

- (void)showMissingServicesAlert {
    
    if (!YikesApplication.isLocked && self.stays.count > 0) {
        
        if (!self.missingDeviceRequirementsVC) {
            self.missingDeviceRequirementsVC = [MissingDeviceRequirementsVC newMissingDeviceRequirementsVCWithMissingServices:self.missingServices];
        }
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:self.missingDeviceRequirementsVC.view];
//        [self presentViewController:self.missingDeviceRequirementsVC animated:false completion:nil];
    }
}

#pragma mark - YKSDashboardCardVCDelegate

- (void)backArrowButtonTouchedFromCardWithIndex:(NSUInteger)cardIndex {
    [self.pageViewController navigateToPageAtIndex:cardIndex-1 animated:YES completion:nil];
}

- (void)nextArrowButtonTouchedFromCardWithIndex:(NSUInteger)cardIndex {
    [self.pageViewController navigateToPageAtIndex:cardIndex+1 animated:YES completion:nil];
}

#pragma mark - SCPageViewControllerDelegate

- (void)pageViewController:(SCPageViewController *)pageViewController didNavigateToOffset:(CGPoint)offset {
    
    [self updateCardTitlesOpacity];
    
}

#pragma mark YikesEngine delegate methods

- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room {
    [self yikesEngineRoomConnectionStatusDidChange:newStatus withRoom:room disconnectReasonCode:kYKSDisconnectReasonCodeUnknown];
}

- (void)yikesEngineRoomConnectionStatusDidChange:(YKSConnectionStatus)newStatus withRoom:(NSString *)room disconnectReasonCode:(YKSDisconnectReasonCode)code {
    
    CLS_LOG(@"handling room connection status change to %@ for room %@", @(newStatus), room);
    [self.unlockDoorTipPresentationController handleRoomConnectionStatusChange:room newStatus:newStatus];
    
    [self.cards enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, YKSDashboardCardVC *card, BOOL *stop) {
        
        if ([card isEqual:[NSNull null]]) {
            return;
        }
        
        [card handleRoomEvent:newStatus forRoomNumber:room disconnectReasonCode:code];
        [card.amenityVC handleRoomEvent:newStatus forRoomNumber:room];
        
    }];
}

- (void)yikesEngineLocationStateDidChange:(YKSLocationState)state {
    
    [self.cards enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, YKSDashboardCardVC *card, BOOL *stop) {
        
        if ([card isEqual:[NSNull null]]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [card setupView];
        });
        
    }];
    
}

- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser {
    
    CLS_LOG(@"UserInfo updated: %@", yikesUser);
    
    [self setupView];
}

- (void)yikesEngineRequiredServicesMissing:(NSSet *)missingServices {
    
    CLS_LOG(@"Missing Services: %@", missingServices);
    
    self.missingServices = [NSSet setWithSet:missingServices];
    
    if (self.showMissingServicesAlertOnLoad) {
        [self showMissingServicesAlert];
        self.showMissingServicesAlertOnLoad = NO;
    }
    
    if (self.missingDeviceRequirementsVC) {
        [self.missingDeviceRequirementsVC updateMissingServices:self.missingServices];
    }
    
    if (missingServices.count > 0) {
        
        [self startMissingServicesButtonPulseWithCount:missingServices.count];
        
    } else {
        
        [self stopMissingServicesButtonPulse];
    }
    
    // send message to cards
    [self.cards enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, YKSDashboardCardVC *card, BOOL *stop) {
        
        if ([card isEqual:[NSNull null]]) {
            return;
        }
        
        [card handleRequiredServicesMissing:missingServices];
        
    }];
}

- (void)yikesEngineErrorDidOccur:(YKSError *)yikesError {
    
    NSMutableDictionary * reportDict = [NSMutableDictionary dictionary];
    
    [reportDict setObject:yikesError.description forKey:@"description"];
    
    if (yikesError.userInfo) {
        
        NSArray * keys = @[@"device", @"os", @"engine_v", @"app_v", @"email"];
        
        for (NSString * key in keys) {
            
            reportDict[key] = yikesError.userInfo[key];
            
        }
        
    }
    
    
    if (yikesError.errorCode == kYKSBluetoothConnectionError) {
       //Code10
        reportDict[@"code"] = @"10";
       
        [Answers logCustomEventWithName:@"Critical BLE Error" customAttributes:[NSDictionary dictionaryWithDictionary:reportDict]];
        
        
    } else if (yikesError.errorCode == kYKSBluetoothServiceDiscoveryError) {
        //Code 3
       
        reportDict[@"code"] = @"3";
        
        [Answers logCustomEventWithName:@"Critical BLE Error" customAttributes:[NSDictionary dictionaryWithDictionary:reportDict]];

        
        
    } else if (yikesError.errorCode == kYKSBluetoothUnknownError) {
        //Code 0
        
        reportDict[@"code"] = @"0";
        
        [Answers logCustomEventWithName:@"Critical BLE Error" customAttributes:[NSDictionary dictionaryWithDictionary:reportDict]];

    } else if (yikesError.errorCode == kYKSBluetoothAuthDoesNotMatchAnyRooms) {
       
        [Answers logCustomEventWithName:@"Guest Auth does not match any rooms" customAttributes:[NSDictionary dictionaryWithDictionary:reportDict]];
        
    }
    
    /*
    if (yikesError.errorCode == kYKSErrorCriticalBluetoothError) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Critical Bluetooth Error";
            configuration.message = @"A rare error has occured with your device's Bluetooth. Please swipe up to bring up Control Center and turn Bluetooth off and then on again.";
            
            [configuration addAction:[PKAlertAction okAction]];
            
        }];
        [self presentViewController:alert animated:NO completion:nil];
        
    }
    */
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
