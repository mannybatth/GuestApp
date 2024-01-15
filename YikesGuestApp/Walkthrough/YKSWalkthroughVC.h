//
//  YKSWalkthroughVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/7/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSWalkthroughVC : UIViewController

@property (weak, nonatomic) IBOutlet UIPageControl * pageControl;
@property (weak, nonatomic) IBOutlet UIButton * skipWalkthroughButton;
@property (weak, nonatomic) IBOutlet UIButton * moreInfoButton;

- (void)refreshGetStartedMissingServices;
- (void)startUsingYikes;

@end
