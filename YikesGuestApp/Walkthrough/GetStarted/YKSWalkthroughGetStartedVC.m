//
//  YKSWalkthroughGetStartedVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/12/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSWalkthroughGetStartedVC.h"
#import "YKSWalkthroughGetStartedTC.h"
#import <CoreLocation/CoreLocation.h>

@interface YKSWalkthroughGetStartedVC () <YKSWalkthroughGetStartedTCDelegate, YikesEngineDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSSet *missingServices;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation YKSWalkthroughGetStartedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self refreshMissingServices];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [AppDelegate addEngineObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [AppDelegate removeEngineObserver:self];
}

- (void)refreshMissingServices {
    
    [[YikesEngine sharedEngine] missingServices:^(NSSet *missingServices) {
        self.missingServices = missingServices;
        [self.tableView reloadData];
    }];
}

- (IBAction)moreInfoButtonTouched:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"AirplaneModeInfo"];
    [self presentViewController:nc animated:YES completion:nil];
    
}

- (IBAction)nextButtonTouched:(id)sender {
    if (self.pvc != nil) {
        [self.pvc navigateToPageAtIndex:self.pvc.currentPage+1 animated:YES completion:nil];
    }
}

#pragma mark - YikesEngineDelegate

- (void)yikesEngineRequiredServicesMissing:(NSSet *)missingServices {
    
    self.missingServices = missingServices;
    [self.tableView reloadData];
}

#pragma mark - YKSWalkthroughGetStartedTCDelegate

- (void)actionButtonTouchedForIndex:(NSInteger)index {
    
    if (index == 0) {
        
        PKAlertViewController *alert =[PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Bluetooth Disabled";
            configuration.message = @"Please open your iOS Control Center or go to Settings to enable Bluetooth.";
            
            [configuration addAction:[PKAlertAction actionWithTitle:@"Ignore" handler:^(PKAlertAction *action, BOOL closed) {
                
            }]];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else if (index == 1) {
        
        if (!self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
        }
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        
    } else if (index == 2) {
        
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
            
            if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
                
                [[AppManager sharedInstance] registerForPushNotifications];
                
                return;
            }
            
        }
        
        PKAlertViewController *alert =[PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Push Notifications Disabled";
            configuration.message = @"To re-enable, please go to Settings and turn on Push Notifications for this app.";
            
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
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusDenied) {
        
        PKAlertViewController *alert =[PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Location Services Disabled";
            configuration.message = @"To re-enable, please go to Settings and turn on Location Service for this app.";
            
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
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
    if (status != kCLAuthorizationStatusNotDetermined) {
        
        self.locationManager = nil;
        [self refreshMissingServices];
        
    }
    
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 3) {
        
        UITableViewCell *cell = [YKSWalkthroughGetStartedTC cellForFooterNoteWithTableView:tableView];
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGSize size = [cell.textLabel sizeThatFits:CGSizeMake(cell.textLabel.frame.size.width, CGFLOAT_MAX)];
        
        return size.height + 40.0f;
    }
    
    YKSWalkthroughGetStartedTC *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSWalkthroughGetStartedTC"];
    
    cell.frame = CGRectMake(0, 0, tableView.bounds.size.width, 83);
    [cell setupCellForIndex:indexPath.row];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGSize size = [cell.serviceDescLabel sizeThatFits:CGSizeMake(cell.serviceDescLabel.frame.size.width, CGFLOAT_MAX)];
    
    return size.height + 55.0f;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 3) {
        
        UITableViewCell *cell = [YKSWalkthroughGetStartedTC cellForFooterNoteWithTableView:tableView];
        return cell;
    }
    
    YKSWalkthroughGetStartedTC *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSWalkthroughGetStartedTC" forIndexPath:indexPath];
    
    cell.delegate = self;
    
    [cell setupCellForIndex:indexPath.row];
    [cell setActionButtonToChecked:NO];
    
    if (indexPath.row == 0) {
        
        if (self.missingServices && [self.missingServices containsObject:@(kYKSBluetoothService)]) {
            [cell setActionButtonToChecked:NO];
        } else {
            [cell setActionButtonToChecked:YES];
        }
        
    } else if (indexPath.row == 1) {
        
        if (self.missingServices && [self.missingServices containsObject:@(kYKSLocationService)]) {
            [cell setActionButtonToChecked:NO];
        } else {
            [cell setActionButtonToChecked:YES];
        }
        
    } else if (indexPath.row == 2) {
        
        if (self.missingServices && [self.missingServices containsObject:@(kYKSPushNotificationService)]) {
            [cell setActionButtonToChecked:NO];
        } else {
            [cell setActionButtonToChecked:YES];
        }
        
    }
    
    return cell;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
