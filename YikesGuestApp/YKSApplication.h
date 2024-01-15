//
//  YKSApplication.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/18/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSApplication : UIApplication

@property (nonatomic, strong) NSDate *lockoutDate;
@property (nonatomic, strong) NSDate *backgroundedDate;

@property (nonatomic) BOOL isBackgrounded;
@property (nonatomic) BOOL isLockedOut;
@property (nonatomic) BOOL isLocked;

- (BOOL)runsOniOS10_0_X;
- (void)resetIdleTimer;

@end
