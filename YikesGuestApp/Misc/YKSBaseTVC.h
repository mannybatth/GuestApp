//
//  YKSBaseTVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 2/1/16.
//  Copyright © 2016 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSBaseTVC : UITableViewController

- (void)appDidBecomeActiveNotification:(NSNotification *)notification;
- (void)appDidEnterBackgroundNotification:(NSNotification *)notification;

@end
