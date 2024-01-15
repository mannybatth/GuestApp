//
//  YKSSharedKeysVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSharedKeysVC.h"
#import "YKSDashboardCardOptionsVC.h"
#import "YKSDashboardCardVC.h"
#import "YKSSharedKeysTC.h"
#import "YKSContactPickerVC.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface YKSSharedKeysVC () <YKSSharedKeysTCDelegate, UIAlertViewDelegate, YKSContactPickerVCDelegate>

@property (nonatomic, strong) NSMutableArray *listOfStayShares;
@property (nonatomic, strong) NSMutableArray *listOfInvites;

@property (nonatomic, strong) YKSDashboardCardOptionsVC *optionsVC;

@end

@implementation YKSSharedKeysVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setSeparatorColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3f]];
    
    [self processHotelAssets];
    [self setupView];
    
    [[YikesEngine sharedEngine] getUserStayShareRequestsWithSuccess:^(NSArray<YKSStayShareInfo *> *stayShares) {
        
        [[YikesEngine sharedEngine] getUserInvitesWithSuccess:^(NSArray<YKSUserInviteInfo *> *userInvites) {
            
            [self setupViewAndReloadTable];
            
        } failure:^(YKSError *error) {
            
            [self setupViewAndReloadTable];
            
        }];
        
    } failure:^(YKSError *error) {
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [AppDelegate addEngineObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [AppDelegate removeEngineObserver:self];
}

- (void)setupViewAndReloadTable {
    [self setupView];
    [self.tableView reloadData];
    [self.dashCardVC numberOfSharedKeysDidChange];
}

- (void)setupView {
    
    self.listOfStayShares = [NSMutableArray new];
    self.listOfInvites = [NSMutableArray new];
    
    // Only show stay shares created by user and for this stay
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    for (YKSStayShareInfo *stayShare in user.stayShares) {
        if ([stayShare.primaryGuest.userId isEqualToNumber:user.userId] &&
            [stayShare.stay.stayId isEqualToNumber:self.stay.stayId] &&
            ![stayShare.status isEqualToString:@"cancelled"] &&
            ![stayShare.status isEqualToString:@"declined"]) {
            
            [self.listOfStayShares addObject:stayShare];
        }
    }
    
    // Only show invites for this stay and have not yet been accepted/declined
    for (YKSUserInviteInfo *userInvite in user.userInvites) {
        if ([userInvite.relatedStayId isEqualToNumber:self.stay.stayId] &&
            userInvite.isAccepted == NO &&
            userInvite.isDeclined == NO) {
            
            [self.listOfInvites addObject:userInvite];
        }
    }
    
    // Update title to show number of active shares
    if (self.listOfStayShares.count > 0) {
        self.title = [NSString stringWithFormat:@"%lu shared key%@", (unsigned long)self.listOfStayShares.count, (self.listOfStayShares.count == 1) ? @"" : @"s"];
    } else {
        self.title = @"shared keys";
    }
    
    // Hide/Show caption label in tableview footer
    if (self.listOfStayShares.count > 0 ||
        self.listOfInvites.count > 0) {
        
        self.tableView.tableFooterView.hidden = YES;
        
    } else {
        
        self.tableView.tableFooterView.hidden = NO;
    }
    
    [self.optionsVC updateSharedKeysCountBadge];
}

- (void)processHotelAssets {
    
    NSString *hotelDashboardImageURL = [YKSAssetsHelper hotelDashboardImageURLForStay:self.stay];
    
    [self.hotelBgImageView sd_setImageWithURL:[NSURL URLWithString:hotelDashboardImageURL]
                             placeholderImage:[UIImage imageNamed:@"hotel_bg"]];
}

- (IBAction)closeButtonTapped:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonTapped:(id)sender {
    
    NSUInteger numOfStaySharesAndInvites = self.listOfStayShares.count + self.listOfInvites.count;
    
    if (self.stay.maxStaySharesAllowed != nil &&
        numOfStaySharesAndInvites >= self.stay.maxStaySharesAllowed.integerValue) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Maximum keys reached";
            configuration.message = [NSString stringWithFormat:@"Cannot add any more keys. \n max allowed: %@ keys", self.stay.maxStaySharesAllowed];
            
            [configuration addAction:[PKAlertAction okAction]];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"YKSContactPickerNC"];
    
    YKSContactPickerVC *contactPickerVC = (YKSContactPickerVC *)nc.topViewController;
    contactPickerVC.delegate = self;
    [self presentViewController:nc animated:YES completion:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"OptionsViewSegue"]) {
        
        self.optionsVC = segue.destinationViewController;
        self.optionsVC.sharedKeysButtonSelected = YES;
        self.optionsVC.stay = self.stay;
        
    }
    
}

#pragma mark - YKSContactPickerVCDelegate

- (void)didSelectContactWithInfo:(YKSContactInfo *)contactInfo {
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:@"Sending share request.."];
    
    for (YKSStayShareInfo *stayShare in self.listOfStayShares) {
        if ([stayShare.secondaryGuest.email isEqualToString:contactInfo.user.email]) {
            [SVProgressHUD showErrorWithStatus:@"A share request has already been sent to this email."];
            return;
        }
    }
    
    for (YKSUserInviteInfo *userInvite in self.listOfInvites) {
        if ([userInvite.email isEqualToString:contactInfo.user.email]) {
            [SVProgressHUD showErrorWithStatus:@"A invite has already been sent to this email."];
            return;
        }
    }
    
    if ([contactInfo.user.email isEqualToString:[[YikesEngine sharedEngine] userInfo].email]) {
        [SVProgressHUD showErrorWithStatus:@"Sorry, cannot share a key with yourself. Select another contact."];
        return;
    }
    
    [[YikesEngine sharedEngine] sendStayShareRequestForStayId:self.stay.stayId toEmail:contactInfo.user.email success:^(YKSStayShareInfo *stayShare, YKSUserInviteInfo *userInvite) {
        
        [self setupViewAndReloadTable];
        [SVProgressHUD dismiss];
        
    } failure:^(YKSError *error) {
        
        [SVProgressHUD showErrorWithStatus:error.description];
        
    }];
    
}

#pragma mark - YKSSharedKeysTCDelegate

- (void)resendShareButtonTouched:(YKSSharedKeysTC *)cell {
    
}

- (void)deleteShareButtonTouched:(YKSSharedKeysTC *)cell {
    
    if (cell.stayShare) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Remove Key";
            configuration.message = @"Are you sure you want to remove this key?";
            
            [configuration addAction:[PKAlertAction cancelAction]];
            [configuration addAction:[PKAlertAction actionWithTitle:@"Yes" handler:^(PKAlertAction *action, BOOL closed) {
                
                if (closed) {
                    
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                    [SVProgressHUD showWithStatus:@"Deleting share.."];
                    
                    [[YikesEngine sharedEngine] cancelStayShareRequest:cell.stayShare success:^{
                        
                        [self setupViewAndReloadTable];
                        [SVProgressHUD dismiss];
                        
                    } failure:^(YKSError *error) {
                        
                        [SVProgressHUD showErrorWithStatus:error.description];
                        
                    }];
                    
                }
                
            }]];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else if (cell.userInvite) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Cancel Invite";
            configuration.message = @"Are you sure you want to cancel this invite?";
            
            [configuration addAction:[PKAlertAction cancelAction]];
            [configuration addAction:[PKAlertAction actionWithTitle:@"Yes" handler:^(PKAlertAction *action, BOOL closed) {
                
                if (closed) {
                    
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                    [SVProgressHUD showWithStatus:@"Cancelling invite.."];
                    
                    [[YikesEngine sharedEngine] cancelUserInviteRequest:cell.userInvite success:^{
                        
                        [self setupViewAndReloadTable];
                        [SVProgressHUD dismiss];
                        
                    } failure:^(YKSError *error) {
                        
                        [SVProgressHUD showErrorWithStatus:error.description];
                        
                    }];
                    
                }
                
            }]];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
}

#pragma mark YikesEngine delegate methods

- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser {
    
    [self setupViewAndReloadTable];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:@"YKSSharedKeysHeader"];
    
    if (section == 1 && self.listOfInvites.count > 0) {
        headerView.textLabel.text = [NSString stringWithFormat:@"%lu invite%@", (unsigned long)self.listOfInvites.count, (self.listOfInvites.count == 1) ? @"" : @"s"];
    }
    
    return headerView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && self.listOfInvites.count > 0) {
        return 28.0f;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return self.listOfStayShares.count;
    } else {
        return self.listOfInvites.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSSharedKeysTC *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSSharedKeysTC" forIndexPath:indexPath];
    
    cell.delegate = self;
    
    if (indexPath.section == 0) {
        
        YKSStayShareInfo *stayShare = [self.listOfStayShares objectAtIndex:indexPath.row];
        [cell setupViewWithStayShare:stayShare];
    } else {
        
        YKSUserInviteInfo *invite = [self.listOfInvites objectAtIndex:indexPath.row];
        [cell setupViewWithUserInvite:invite];
    }
    
    return cell;
    
}

@end
