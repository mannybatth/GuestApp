//
//  YKSNotificationsVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 9/1/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSNotificationsVC.h"
#import "YKSNotificationsTC.h"

@interface YKSNotificationsVC () <YKSNotificationsTCDelegate, YikesEngineDelegate>

@property (nonatomic, strong) NSMutableArray *listOfStayShares;

@end

@implementation YKSNotificationsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setSeparatorColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3f]];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64.0f, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(64.0f, 0, 0, 0);
    
    [self reloadListOfStayShares];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [AppDelegate addEngineObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [AppDelegate removeEngineObserver:self];
}

- (void)reloadTableViewAndData {
    [self reloadListOfStayShares];
    [self.tableView reloadData];
}

- (void)reloadListOfStayShares {
    
    self.listOfStayShares = [NSMutableArray new];
    
    // Only get stay shares sent to this user
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    for (YKSStayShareInfo *stayShare in user.stayShares) {
        if ([stayShare.secondaryGuest.userId isEqualToNumber:user.userId] &&
            [stayShare.status isEqualToString:@"pending"]) {
            
            [self.listOfStayShares addObject:stayShare];
        }
    }
    
    if (self.listOfStayShares.count > 0) {
        self.noNotificationsLabel.hidden = YES;
    } else {
        self.noNotificationsLabel.hidden = NO;
    }
}

#pragma mark - YKSNotificationsTCDelegate

- (void)acceptShareButtonTouched:(YKSNotificationsTC *)cell {
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:@"Accepting share request.."];
    
    [[YikesEngine sharedEngine] acceptStayShareRequest:cell.stayShare success:^{
        
        [self reloadTableViewAndData];
        
        [SVProgressHUD dismiss];
        
    } failure:^(YKSError *error) {
        
        [SVProgressHUD showErrorWithStatus:error.description];
        
    }];
    
}

- (void)declineShareButtonTouched:(YKSNotificationsTC *)cell {
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:@"Declining share request.."];
    
    [[YikesEngine sharedEngine] declineStayShareRequest:cell.stayShare success:^{
        
        [self reloadListOfStayShares];
        [self.tableView reloadData];
        
        [SVProgressHUD dismiss];
        
    } failure:^(YKSError *error) {
        
        [SVProgressHUD showErrorWithStatus:error.description];
        
    }];
    
}

#pragma mark YikesEngine delegate methods

- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser {
    
    [self reloadTableViewAndData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.listOfStayShares.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSStayShareInfo *stayShare = [self.listOfStayShares objectAtIndex:indexPath.row];
    
    YKSNotificationsTC *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSNotificationsTC" forIndexPath:indexPath];
    
    cell.delegate = self;
    [cell setupViewWithStayShare:stayShare];
    
    return cell;
    
}

@end
