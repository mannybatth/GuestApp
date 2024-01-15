//
//  YKSDashboardNC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 6/29/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSDashboardNC.h"

@import YikesGenericEngine;

@interface YKSDashboardNC ()

@property (nonatomic, strong) UINavigationController *notificationsNC;

@end

@implementation YKSDashboardNC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Transparent navigationbar
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.tintColor = [UIColor clearColor];
    
    // On Login, display the Low Power warning if applicable:
    [[YikesEngine sharedInstance] checkIfLowPowerModeIsEnabled];
}

- (void)toggleNotificationsView:(id)sender {
    
    UIBarButtonItem *bellIconButton = (UIBarButtonItem *)sender;
    
    bellIconButton.enabled = NO;
    
    if (self.notificationsNC) {
        
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^(void) {
            
            self.notificationsNC.view.frame = CGRectMake(self.notificationsNC.view.frame.origin.x,
                                       -self.notificationsNC.view.frame.size.height,
                                       self.notificationsNC.view.frame.size.width,
                                       self.notificationsNC.view.frame.size.height);
            
        } completion:^(BOOL finished) {
            
            bellIconButton.enabled = YES;
            [self.notificationsNC removeFromParentViewController];
            [self.notificationsNC.view removeFromSuperview];
            self.notificationsNC = nil;
            
        }];
        
        return;
        
    }
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.notificationsNC = [storyboard instantiateViewControllerWithIdentifier:@"YKSNotificationsNC"];
    
    self.notificationsNC.view.frame = CGRectMake(self.notificationsNC.view.frame.origin.x,
                               -self.notificationsNC.view.frame.size.height,
                               self.notificationsNC.view.frame.size.width,
                               self.notificationsNC.view.frame.size.height);
    
    [self addChildViewController:self.notificationsNC];
    [self.view insertSubview:self.notificationsNC.view belowSubview:self.navigationBar];
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
        
        self.notificationsNC.view.frame = CGRectMake(self.notificationsNC.view.frame.origin.x,
                                   0,
                                   self.notificationsNC.view.frame.size.width,
                                   self.notificationsNC.view.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        bellIconButton.enabled = YES;
        
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
