//
//  YKSSideBarVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/9/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSideBarVC.h"
#import "UIViewController+MMDrawerController.h"
#import "YKSDashboardNC.h"
#import "YKSDashboardVC.h"
#import "YKSSettingsNC.h"
#import "YKSSettingsTVC.h"

@interface YKSSideBarVC ()

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) CGRect originalNavBarFrame;
@property (nonatomic) CGRect adjustedNavBarFrame;

@end

@implementation YKSSideBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.avatarView.layer.cornerRadius = 75;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.borderWidth = 1.0f;
    self.avatarView.layer.borderColor = [UIColor colorWithHexString:@"DADADA"].CGColor;
    self.avatarView.backgroundColor = [UIColor whiteColor];
    
    self.selectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    self.userInitialsLabel.text = [NSString stringWithFormat:@"%@%@", [user.firstName substringToIndex:1], [user.lastName substringToIndex:1]];
    self.fullNameLabel.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
    self.emailLabel.text = user.email;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideStatusBar:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self slideStatusBarUp];
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top) animated:NO];
    [self sizeHeaderToFit];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self slideStatusBarDown];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)sizeHeaderToFit {
    UIView *headerView = self.tableView.tableHeaderView;
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
    
    CGFloat height = [headerView systemLayoutSizeFittingSize:(UILayoutFittingCompressedSize)].height;
    CGRect frame = headerView.frame;
    frame.size.height = height;
    headerView.frame = frame;
    
    self.tableView.tableHeaderView = headerView;
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    [self slideStatusBarUp];
}

- (void)showHideStatusBar:(NSNotification *)notification {
    if ([self isSideMenuOpen] &&
        (notification.name == UIApplicationDidChangeStatusBarFrameNotification)) {
        if (![self isStatusBarFrameTall]) {
            [self slideStatusBarUp];
        }
    }
}

- (BOOL)isSideMenuOpen {
    return self.mm_drawerController.openSide == MMDrawerSideLeft;
}



- (void)slideStatusBarUp {
    
    UINavigationController *middleVC = (UINavigationController*)self.mm_drawerController.centerViewController;
    
    if (CGRectIsEmpty(self.originalNavBarFrame)) {
        self.originalNavBarFrame = middleVC.navigationBar.frame;
        self.adjustedNavBarFrame = CGRectMake(middleVC.navigationBar.frame.origin.x,
                                              self.originalNavBarFrame.origin.y - 20,
                                              middleVC.navigationBar.frame.size.width,
                                              self.originalNavBarFrame.size.height + 20);
    }
    
    middleVC.navigationBar.frame = self.adjustedNavBarFrame;
    
    if ([self isStatusBarFrameTall] || [[UIApplication sharedApplication] isStatusBarHidden
        ]) {
        NSLog(@"Not hiding the status bar during a call / GPS usage / already hidden.");
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
    
    [UIView animateWithDuration:0.35
                     animations:^{
                         middleVC.navigationBar.frame = self.adjustedNavBarFrame;
                     } completion:nil];
    
}

- (void)slideStatusBarDown {
    
    UINavigationController *middleVC = (UINavigationController*)self.mm_drawerController.centerViewController;
    
    middleVC.navigationBar.frame = self.adjustedNavBarFrame;
    middleVC.navigationBar.frame = self.originalNavBarFrame;
    
    // Adding a small delay to this animation helps iOS handle the window changes:
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    });
    
    [UIView animateWithDuration:0.35
                     animations:^{
                         middleVC.navigationBar.frame = self.originalNavBarFrame;
                     } completion:nil];
}

- (BOOL)isStatusBarFrameTall {
    CGRect frame = [UIApplication sharedApplication].statusBarFrame;
    // Note: There doesn't seem to be a system constant for the 20 pts height...
    return frame.size.height > 20;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return 2;
    }
    return 0;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    view.tintColor = [UIColor colorWithHexString:@"D3D3D3"];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSSideBarTC" forIndexPath:indexPath];
    
    NSString *imageName;
    if (indexPath.section == 0) {

        if (indexPath.row == 0) {
            
            cell.textLabel.text = @"dashboard";
            imageName = @"dashboard_icon";
            
//        } else if (indexPath.row == 1) {
//            
//            cell.textLabel.text = @"history";
//            imageName = @"history_icon";
//            
//        } else if (indexPath.row == 2) {
//            
//            cell.textLabel.text = @"notifications";
//            imageName = @"notifications_icon";
            
        } else if (indexPath.row == 1) {
            
            cell.textLabel.text = @"settings";
            imageName = @"settings_icon";
            
        }
        
    } else if (indexPath.section == 1) {
        
//        if (indexPath.row == 0) {
//            
//            cell.textLabel.text = @"tips";
//            imageName = @"tips_icon";
        
        if (indexPath.row == 0) {
            
            cell.textLabel.text = @"follow on twitter";
            imageName = @"twitter_icon";
            
        } else if (indexPath.row == 1) {
            
            cell.textLabel.text = @"like on facebook";
            imageName = @"fb_icon";
            
        }
    }
    
    if ([self.selectedIndexPath compare:indexPath] == NSOrderedSame) {
        cell.textLabel.textColor = [UIColor colorWithHexString:@"5F9318"];
        imageName = [NSString stringWithFormat:@"%@_on", imageName];
    } else {
        cell.textLabel.textColor = [UIColor colorWithHexString:@"4A4A4A"];
    }
    
    cell.imageView.image = [UIImage imageNamed:imageName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *oldSelected = self.selectedIndexPath;
    self.selectedIndexPath = indexPath;
    
    if ([oldSelected compare:indexPath] == NSOrderedSame) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
    } else {
        [tableView reloadRowsAtIndexPaths:@[oldSelected, indexPath] withRowAnimation:NO];
    }
    
    UINavigationController *navController = (UINavigationController*)self.mm_drawerController.centerViewController;
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            
            if (![navController isKindOfClass:[YKSDashboardNC class]]) {
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                YKSDashboardNC *dashboardNC = [sb instantiateViewControllerWithIdentifier:@"YKSDashboardNC"];
                [self.mm_drawerController setCenterViewController:dashboardNC];
            }
            
            [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
            
        } else if (indexPath.row == 1) {
            
            if (![navController isKindOfClass:[YKSSettingsNC class]]) {
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
                YKSSettingsNC *settingsNC = [sb instantiateViewControllerWithIdentifier:@"YKSSettingsNC"];
                [self.mm_drawerController setCenterViewController:settingsNC];
            }
            
            [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
            
        }
        
    } else if (indexPath.section == 1) {
        
        if (indexPath.row == 0) {
            
            NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=yikesCo"];
            if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
                [[UIApplication sharedApplication] openURL:twitterURL];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/yikesCo"]];
            }
            
        } else if (indexPath.row == 1) {
            
            NSURL *facebookURL = [NSURL URLWithString:@"fb://page?id=170170069784430"];
            if ([[UIApplication sharedApplication] canOpenURL:facebookURL]) {
                [[UIApplication sharedApplication] openURL:facebookURL];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/yikes.co"]];
            }
            
        }
        
    }
    
}

@end
