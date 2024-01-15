//
//  YKSWalkthroughVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/7/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSWalkthroughVC.h"
#import "YKSWalkthroughCardVC.h"
#import "YKSWalkthroughGetStartedVC.h"

#import "SCPageViewController.h"
#import "SCScrollView.h"
#import "SCEasingFunction.h"
#import "SCParallaxPageLayouter.h"

@interface YKSWalkthroughVC () <SCPageViewControllerDataSource, SCPageViewControllerDelegate>

@property (nonatomic, strong) SCPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableDictionary *cards;

@end

@implementation YKSWalkthroughVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.cards = [NSMutableDictionary dictionary];
    
    UIStoryboard *app = [UIStoryboard storyboardWithName:@"Walkthrough" bundle:nil];
    
    // load the walkthrough cards:
    for (int i=2; i<=6; i++) {
        
        YKSWalkthroughCardVC *card = [app instantiateViewControllerWithIdentifier:[NSString stringWithFormat:@"WalkthroughCard%i", i]];
        [self.cards setObject:card forKey:@(i-1)];
        
    }
    
    // load the "Get started navigation controller:
    UINavigationController *getStartedNC = [app instantiateViewControllerWithIdentifier:@"WalkthroughCard1"];
    YKSWalkthroughGetStartedVC *vc = (YKSWalkthroughGetStartedVC*)getStartedNC.topViewController;
    [self.cards setObject:getStartedNC forKey:@(0)];
    
    self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
    
    [self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    [self.pageViewController setContinuousNavigationEnabled:NO];

    [self addChildViewController:self.pageViewController];
    [self.pageViewController.view setFrame:self.view.bounds];
    [self.view insertSubview:self.pageViewController.view belowSubview:self.skipWalkthroughButton];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.pageControl.numberOfPages = self.cards.count;
    self.pageControl.currentPage = 0;
    
    vc.pvc = self.pageViewController;
    
}

- (void)startUsingYikes {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WalkthroughPlayedAlready"];
    
    if (self.navigationController.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [AppDelegate goToLoginView];
    }
}

- (IBAction)skipWalkthroughButtonTouched:(id)sender {
    
    [self startUsingYikes];
    
}

- (IBAction)moreInfoButtonTouched:(id)sender {
    
    if (self.pageViewController.currentPage == 3) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Walkthrough" bundle:nil];
        UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"YourRoomMoreInfo"];
        [self presentViewController:nc animated:YES completion:nil];
        
    } else if (self.pageViewController.currentPage == 5) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Walkthrough" bundle:nil];
        UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"PeaceOfMindMoreInfo"];
        [self presentViewController:nc animated:YES completion:nil];
        
    }
}

- (void)showMoreInfoButton {
    
    [UIView transitionWithView:self.moreInfoButton
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.moreInfoButton.hidden = NO;
}

- (void)hideMoreInfoButton {
    
    [UIView transitionWithView:self.moreInfoButton
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.moreInfoButton.hidden = YES;
    
}

- (void)showSkipWalkthroughButton {
    
    if (self.pageViewController.currentPage == self.cards.count-1) {
        [self.skipWalkthroughButton setTitle:@"Start" forState:UIControlStateNormal];
    }
    else {
        [self.skipWalkthroughButton setTitle:@"skip walkthrough" forState:UIControlStateNormal];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.skipWalkthroughButton.hidden = NO;
        
        [UIView transitionWithView:self.skipWalkthroughButton
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
    });
    
}

- (void)hideSkipWalkthroughButton {
    
    [UIView transitionWithView:self.skipWalkthroughButton
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.skipWalkthroughButton.hidden = YES;
    
}

- (void)showPageControl {
    
    [UIView transitionWithView:self.pageControl
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.pageControl.hidden = NO;
    
}

- (void)hidePageControl {
    
    [UIView transitionWithView:self.pageControl
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    
    self.pageControl.hidden = YES;
    
}

- (void)refreshGetStartedMissingServices {
    
    UINavigationController *getStartedNC = [self.cards objectForKey:@(0)];
    YKSWalkthroughGetStartedVC *walkthroughGetStartedVC = (YKSWalkthroughGetStartedVC *)getStartedNC.topViewController;
    [walkthroughGetStartedVC refreshMissingServices];
    
}

#pragma mark - SCPageViewControllerDataSource

- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController {
    
    return self.cards.count;
    
}

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController
            viewControllerForPageAtIndex:(NSUInteger)pageIndex {
    
    id card = [self.cards objectForKey:@(pageIndex)];
    
    return card;
}

#pragma mark - SCPageViewControllerDelegate

- (void)pageViewController:(SCPageViewController *)pageViewController didNavigateToPageAtIndex:(NSUInteger)pageIndex {
    
    self.pageControl.currentPage = pageIndex;
    
    if (pageIndex != 0) {
        
        [self showSkipWalkthroughButton];
        [self showPageControl];
        
    }
    
    if (pageIndex == 3 || pageIndex == 5 || pageIndex == self.cards.count-1) {
        [self showMoreInfoButton];
    }
    
}

- (void)pageViewController:(SCPageViewController *)pageViewController didShowViewController:(UIViewController *)controller atIndex:(NSUInteger)index {
    
    if (index != 3 && index != 5) {
        [self hideMoreInfoButton];
    }
    
    if (index == 0) {
        [self hideMoreInfoButton];
        [self hideSkipWalkthroughButton];
        [self hidePageControl];
        self.pageViewController.scrollView.bounces = NO;
    }
    else {
        self.pageViewController.scrollView.bounces = YES;
    }
    
}

- (void)pageViewController:(SCPageViewController *)pageViewController didHideViewController:(UIViewController *)controller atIndex:(NSUInteger)index {
    
    if (index != 3 && index != 5) {
        [self hideMoreInfoButton];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
