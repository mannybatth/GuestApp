//
//  YKSBaseVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/20/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSBaseVC.h"
#import "YKSPasscodeScreenVC.h"

#import "UIViewController+MMDrawerController.h"

@interface YKSBaseVC ()

@property (nonatomic, strong) UIView *blurView;

@end

@implementation YKSBaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (YikesApplication.isLocked) {
        [self showDashboardBlur];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appLockScreenIsPresented:)
                                                 name:kApplicationLockScreenIsPresented
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appLockScreenIsDismissed:)
                                                 name:kApplicationLockScreenIsDismissed
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kApplicationLockScreenIsPresented object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kApplicationLockScreenIsDismissed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appLockScreenIsPresented:(NSNotification *)notification {
    [self showDashboardBlur];
}

- (void)appLockScreenIsDismissed:(NSNotification *)notification {
    [self hideDashboardBlurWithAnimation:YES];
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    
    // wait until we know whether the app should be locked
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (YikesApplication.isLocked) {
            [self showDashboardBlur];
        } else {
            [self hideDashboardBlurWithAnimation:YES];
        }
    });
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification {
    if ([YKSPasscodeScreenVC isPasscodeSet]) {
        [self showDashboardBlur];
    }
}

- (void)showDashboardBlur {
    
    if (!self.blurView) {
        
        if (NSClassFromString(@"UIVisualEffectView")) {
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            
        } else {
            
            self.blurView = [[UIView alloc] initWithFrame:self.navigationController.view.bounds];
            [self.blurView setBackgroundColor:[UIColor blackColor]];
        }
        
    }
    self.blurView.frame = self.mm_drawerController.view.bounds;
    if (self.blurView.superview) [self.blurView removeFromSuperview];
    self.blurView.alpha = 1;
    self.blurView.tag = 27;
    for (UIView *subview in self.mm_drawerController.view.subviews) {
        if (subview.tag == self.blurView.tag) {
            [subview removeFromSuperview];
        }
    }
    [self.mm_drawerController.view addSubview:self.blurView];
    self.blurView.hidden = NO;
}

- (void)hideDashboardBlurWithAnimation:(BOOL)animate {
    
    if (self.blurView) {
        if (animate) {
            
            [UIView transitionWithView:self.blurView
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.blurView.hidden = YES;
                            } completion:^(BOOL finished) {
                                [self.blurView removeFromSuperview];
                            }];
            
        } else {
            [self.blurView removeFromSuperview];
        }
    }
}

@end
