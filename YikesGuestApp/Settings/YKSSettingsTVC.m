//
//  YKSSettingsTVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/11/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSettingsTVC.h"
#import "AppManager.h"
#import "YKSUtilities.h"
#import "YKSPasscodeScreenVC.h"
#import "SVWebViewController.h"

@import Crashlytics;
@import HexColors;
@import YikesGenericEngine;

@interface YKSSettingsTVC () <YKSPasscodeScreenVCDelegate>

@property (nonatomic, strong) YKSPasscodeScreenVC *passcodeSVC;
@property (nonatomic, strong, nullable) UISwitch *enableTipsSwitch;

#define YIKES_DEBUG_NOTIFICATIONS @"com.yikesteam.YikesEngineSP debug notifications"

@end

@implementation YKSSettingsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.versionNumberLabel.text = [NSString stringWithFormat:@"VERSION %@", [AppManager fullVersionString]];
    
    NSString *email = [[[YikesEngine sharedEngine] userInfo] email];
    if ([email containsString:@"yamm.ca"] || [email containsString:@"yikes.co"]) {
        self.debugNotificationsLabel.hidden = NO;
        self.debugNotificationsSwitch.hidden = NO;
        BOOL showDebugNotifications = [[NSUserDefaults standardUserDefaults] boolForKey:YIKES_DEBUG_NOTIFICATIONS];
        self.debugNotificationsSwitch.on = showDebugNotifications;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [YKSUtilities hideShowApiLabel:self.envLabelSettings];
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification {
    [super appDidEnterBackgroundNotification:notification];
    
    if (self.passcodeSVC && self.passcodeSVC.mode != kYKSPasscodeViewModeUnlock) {
        [self dismissPasscodeSVC];
    }
}

- (IBAction)hamburgerMenuButtonTapped:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)logout:(id)sender {
    
    // Log before the logout to know about the user:
    YKSUserInfo *userInfo = [YikesEngine sharedInstance].userInfo;
    if (userInfo) {
        DLog(@"Logging out user %@", userInfo.email);
        [Answers logCustomEventWithName:@"Logout" customAttributes:@{@"username": [YikesEngine sharedInstance].userInfo.email,
                                                                     @"yCentral Environment": @([YikesEngine sharedEngine].currentApiEnv).stringValue}];
    }
    else {
        DLog(@"No user info on logout");
    }
    
    [[YikesEngine sharedInstance] stopEngineWithSuccess:^{
        
    }];
    
    [AppDelegate goToLoginView];
}



#pragma mark - YKSPasscodeScreenVCDelegate

- (void)successfullyCreatedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
    [self.tableView reloadData];
    [self dismissPasscodeSVC];
    
}

- (void)successfullyChangedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
    [self.tableView reloadData];
    [self dismissPasscodeSVC];
    
}

- (void)successfullyDeletedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
    [self.tableView reloadData];
    [self dismissPasscodeSVC];
    
}

- (void)passcodeEntryWasCancelledForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC {
    
    [self dismissPasscodeSVC];
    
}

- (void)dismissPasscodeSVC {
    if (self.passcodeSVC) {
        [self.passcodeSVC dismiss];
        self.passcodeSVC = nil;
    }
}

- (void)playWalkthrough {
    
    [AppDelegate presentWalkthroughOverViewController:self];
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 3;
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        return @"GENERAL";
//    } else if (section == 1) {
//        return @"ABOUT US";
//    }
//    return @"HELP";
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSSettingsSectionHeaderTC"];
//    
//    cell.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
//    
//    return cell;
//}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor colorWithHexString:@"4A4A4A"]];
    [header.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]];
    
}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if (section == 0) {
//        return 1;
////        if (![YKSPasscodeScreenVC isPasscodeSet]) {
////            return 2;
////        } else {
////            return 4;
////        }
//    } else if (section == 1) {
//        return 4;
//    }
//    return 1;
//}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSSettingsTC" forIndexPath:indexPath];
//    
//    if (indexPath.section == 0) {
//        
//        if (indexPath.row == 0) {
//            cell.textLabel.text = @"passcode & Touch ID";
//        }
//        
////        if (![YKSPasscodeScreenVC isPasscodeSet]) {
////            
////            if (indexPath.row == 0) {
////                cell.textLabel.text = @"set passcode";
////            } else if (indexPath.row == 1) {
////                cell.textLabel.text = @"play walkthrough";
////            }
////            
////        } else {
////            
////            if (indexPath.row == 0) {
////                cell.textLabel.text = @"change passcode";
////            } else if (indexPath.row == 1) {
////                cell.textLabel.text = @"delete passcode";
////            } else if (indexPath.row == 2) {
////                cell.textLabel.text = @"reset passcode & logout";
////            } else if (indexPath.row == 3) {
////                cell.textLabel.text = @"play walkthrough";
////            }
////        }
//        
//    } else if (indexPath.section == 1) {
//        
//        if (indexPath.row == 0) {
//            cell.textLabel.text = @"y!kes website";
//        } else if (indexPath.row == 1) {
//            cell.textLabel.text = @"like us on Facebook";
//        } else if (indexPath.row == 2) {
//            cell.textLabel.text = @"follow us on Twitter";
//        } else if (indexPath.row == 3) {
//            cell.textLabel.text = @"privacy policy";
//        }
//        
//    } else if (indexPath.section == 2) {
//        
//        if (indexPath.row == 0) {
//            cell.textLabel.text = @"y!kes walkthough";
//        }
//        
//    }
//    
//    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    
//    return cell;
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_yikes_logo_small"]];
            
        } else if (indexPath.row == 1) {
            
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_facebook"]];
            
        } else if (indexPath.row == 2) {
            
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_twitter"]];
            
        }
        
    } else if (indexPath.section == 2) {
        
        if (indexPath.row == 2) {
            
            BOOL areTipsDisabled = [UnlockDoorTipPresentationController areTipsDisabled];
            self.enableTipsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 51.0f, 31.0f)];
            [self.enableTipsSwitch setOn:!areTipsDisabled];
            [self.enableTipsSwitch addTarget:self
                                      action:@selector(tipsSwitchValueChanged:)
                            forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = self.enableTipsSwitch;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
        }
//        if (![YKSPasscodeScreenVC isPasscodeSet]) {
//            
//            if (indexPath.row == 0) {
//                self.passcodeSVC = [YKSPasscodeScreenVC passcodeScreenWithMode:kYKSPasscodeViewModeCreate];
//            } else if (indexPath.row == 1) {
//                [self playWalkthrough];
//            }
//            
//        } else {
//            
//            if (indexPath.row == 2) {
//                
//                PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
//                    
//                    configuration.message = @"Are you sure you want to reset passcode & logout?";
//                    
//                    [configuration addAction:[PKAlertAction actionWithTitle:@"Yes" handler:^(PKAlertAction *action, BOOL closed) {
//                        
//                        if (closed) {
//                            [YKSPasscodeScreenVC resetPasscode];
//                            [self logout:nil];
//                        }
//                        
//                    }]];
//                    
//                    [configuration addAction:[PKAlertAction cancelAction]];
//                    
//                }];
//                [self presentViewController:alert animated:YES completion:nil];
//                
//                return;
//            }
//            
//            if (indexPath.row == 0) {
//                self.passcodeSVC = [YKSPasscodeScreenVC passcodeScreenWithMode:kYKSPasscodeViewModeChange];
//            } else if (indexPath.row == 1) {
//                self.passcodeSVC = [YKSPasscodeScreenVC passcodeScreenWithMode:kYKSPasscodeViewModeDelete];
//            } else if (indexPath.row == 3) {
//                [self playWalkthrough];
//            }
//            
//        }
//        
//        if (self.passcodeSVC) {
//            self.passcodeSVC.delegate = self;
//            [self.passcodeSVC presentOverViewController:self.mm_drawerController];
//        }
        
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:@"http://yikes.co"];
            [self.navigationController pushViewController:webViewController animated:YES];
            
        } else if (indexPath.row == 1) {
            
            NSURL *facebookURL = [NSURL URLWithString:@"fb://page?id=170170069784430"];
            if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
                [[UIApplication sharedApplication] openURL:facebookURL];
            } else {

                SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:@"https://www.facebook.com/yikes.co"];
                [self.navigationController pushViewController:webViewController animated:YES];
            }
            
        } else if (indexPath.row == 2) {
            
            NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=yikesCo"];
            if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
                [[UIApplication sharedApplication] openURL:twitterURL];
            } else {

                SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:@"https://twitter.com/yikesCo"];
                [self.navigationController pushViewController:webViewController animated:YES];
            }
            
        } else if (indexPath.row == 3) {
            
            SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:@"http://yikes.co/wp-content/uploads/2015/11/Privacy-Policy.pdf"];
            webViewController.useWebPageTitle = NO;
            webViewController.title = @"privacy policy";
            [self.navigationController pushViewController:webViewController animated:YES];
            
        }
        
    } else if (indexPath.section == 2) {
        
        if (indexPath.row == 0) {
            [self playWalkthrough];
        }
        
    }
    
}

- (void)tipsSwitchValueChanged:(UISwitch *)sender {
    
    BOOL isDisabled = ![sender isOn];
    [UnlockDoorTipPresentationController setAreTipsDisabled:isDisabled];
}
- (IBAction)debugNotificationsSwitched:(id)sender {
    BOOL isOn = [sender isOn];
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:YIKES_DEBUG_NOTIFICATIONS];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
