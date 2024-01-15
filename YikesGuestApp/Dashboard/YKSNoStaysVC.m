//
//  YKSNoStaysVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/11/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSNoStaysVC.h"
#import "YKSDashboardNC.h"
#import "YKSTestAccounts.h"
#import "M13BadgeView.h"

#import <AVFoundation/AVFoundation.h>

@interface YKSNoStaysVC () <YikesEngineDelegate>

@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;

@property (nonatomic, strong) M13BadgeView *notificationsBadge;

@end

@implementation YKSNoStaysVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"no_stays_video" ofType:@"mp4"]]];
    [self.moviePlayer.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
    [self.moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.shouldAutoplay = NO;
    self.moviePlayer.allowsAirPlay = NO;
    [self.moviePlayer prepareToPlay];
    [self.playerView addSubview:self.moviePlayer.view];
    
    id views = @{ @"player": self.moviePlayer.view };
    [self.playerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:views]];
    
    [self.playerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:views]];
    
    [self.moviePlayer play];
    
    self.notificationsBadge = [[M13BadgeView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
    [self.notificationsBadge setFont:[UIFont fontWithName:@"HelveticaNeue" size:10.0]];
    [self.notificationsBadge setBadgeBackgroundColor:[UIColor colorWithHexString:@"5F9318"]];
    [self.notificationsBadge setShadowBadge:NO];
    [self.notificationsBadge setMinimumWidth:18.0f];
    [self.notificationsBadge setAlignmentShift:CGSizeMake(-11.0f, 8.0f)];
    [self.notificationsBadge setHidesWhenZero:YES];
    [[self.navigationItem.rightBarButtonItem valueForKey:@"view"] addSubview:self.notificationsBadge];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (IBAction)viewSwipedUp:(id)sender {
    if ([YKSTestAccounts isTestUser:[[YikesEngine sharedEngine] userInfo].email]) {
        [[YikesEngine sharedEngine] setDebugMode:YES];
        [[YikesEngine sharedEngine] showDebugViewInView:self.view];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [AppDelegate addEngineObserver:self];
    [self setupView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [AppDelegate removeEngineObserver:self];
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    [super appDidBecomeActiveNotification:notification];
    
    if (self.moviePlayer) {
        [self.moviePlayer play];
    }
}

- (IBAction)hamburgerMenuButtonTapped:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)notificationBellButtonTapped:(id)sender {
    [(YKSDashboardNC *)self.navigationController toggleNotificationsView:sender];
}

- (void)setupView {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    if (user.stays &&
        user.stays.count > 0) {
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        return;
    }
    
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

- (IBAction)tappedView:(id)sender {
    
    [self.tapGestureRecognizer setEnabled:NO];
    [self.spinner startAnimating];
    [self.noStaysLabel setHidden:YES];
    [[YikesEngine sharedEngine] refreshUserInfoWithFailure:^(YKSError *error) {
        [self.spinner stopAnimating];
        [self.noStaysLabel setHidden:NO];
        [self.tapGestureRecognizer setEnabled:YES];
    }];
}

- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        [self.noStaysLabel setHidden:NO];
        [self.tapGestureRecognizer setEnabled:YES];
    });
    [self setupView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
