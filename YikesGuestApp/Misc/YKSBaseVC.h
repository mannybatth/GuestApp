//
//  YKSBaseVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/20/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSBaseVC : UIViewController

- (void)appDidBecomeActiveNotification:(NSNotification *)notification;
- (void)appDidEnterBackgroundNotification:(NSNotification *)notification;

@end
