//
//  YKSApplication.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/18/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSApplication.h"

static NSString *kLockoutUserDefaultsKey = @"appLockoutState";
static NSString *kLockoutDateUserDefaultsKey = @"appLockoutDate";
static NSString *kEnterBackgroundDateUserDefaultsKey = @"appEnterBackgroundDate";

@interface YKSApplication()

@property (nonatomic, strong) NSTimer *myidleTimer;

@end

@implementation YKSApplication

//here we are listening for any touch. If the screen receives touch, the timer is reset
- (void)sendEvent:(UIEvent *)event {
    
    [super sendEvent:event];
    
    if (!self.myidleTimer) {
        [self resetIdleTimer];
    }
    
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0) {
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseBegan) {
            [self resetIdleTimer];
        }
    }
}

- (BOOL)runsOniOS10_0_X {
    NSString *minSysVer = @"10.0";
#ifdef DEBUG
    NSString *maxSysVer = @"10.1";
#else
    NSString *maxSysVer = @"10.1";
#endif
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    // currSysVer needs to be >= than iOS 10.0 (not < or ascending)
    if ([currSysVer compare:minSysVer options:NSNumericSearch] != NSOrderedAscending &&
        // currSysVer needs to be < than iOS 10.1
        [currSysVer compare:maxSysVer options:NSNumericSearch] == NSOrderedAscending)
    {
        //TODO: Change to YikesEngine to use the Generic Engine.
//        CLS_LOG(@"Running on iOS 10.0.X: %@", currSysVer);
        return YES;
    }
    else {
        return NO;
    }
        
}

- (void)resetIdleTimer {
    if (self.myidleTimer) {
        [self.myidleTimer invalidate];
    }
    
    int timeout;
    
    // timer for lockout
    if (self.isLockedOut) {
        if (self.lockoutDate) {
            int totalLockoutTime = kApplicationAppLockout;
            NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:self.lockoutDate];
            if (timeDifference > totalLockoutTime) {
                timeout = 0;                                    // lockout time has passed
            } else {
                timeout = totalLockoutTime-timeDifference;      // lockout still has some time left
            }
        } else {
            timeout = kApplicationAppLockout;
        }
        if (timeout > 0) {
            self.myidleTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(lockoutTimerExceeded) userInfo:nil repeats:NO];
        } else {
            [self lockoutTimerExceeded];
        }
        return;
    }
    
    // check background timer when app enters foreground
    if (!self.isBackgrounded) {
        if (self.backgroundedDate) {
            int totalTime = kApplicationBackgroundTimeout;
            NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:self.backgroundedDate];
            if (timeDifference > totalTime) {
                timeout = 0;                                    // time has passed
            } else {
                timeout = kApplicationForegroundTimeout;
            }
        } else {
            timeout = kApplicationForegroundTimeout;
        }
        if (timeout > 0) {
            self.myidleTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
        } else {
            [self idleTimerExceeded];
        }
        return;
    } else {
        timeout = kApplicationBackgroundTimeout;
        self.myidleTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
    }
}

//if the timer reaches the limit as defined in kApplicationTimeout, post this notification
- (void)idleTimerExceeded {
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidTimeoutNotification object:nil];
}

- (void)lockoutTimerExceeded {
    self.isLockedOut = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationLockoutDidEndNotification object:nil];
}



- (void)setIsBackgrounded:(BOOL)isBackgrounded {
    _isBackgrounded = isBackgrounded;
    
    [self resetIdleTimer];
    
    if (isBackgrounded) {
        self.backgroundedDate = [NSDate date];
    } else {
        self.backgroundedDate = nil;
    }
}

- (void)setIsLockedOut:(BOOL)isLockedOut {
    if (isLockedOut) {
        self.lockoutDate = [NSDate date];
    } else {
        self.lockoutDate = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(isLockedOut) forKey:kLockoutUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self resetIdleTimer];
}

- (BOOL)isLockedOut {
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:kLockoutUserDefaultsKey];
    return [num boolValue];
}

- (void)setLockoutDate:(NSDate *)lockoutDate {
    [[NSUserDefaults standardUserDefaults] setObject:lockoutDate forKey:kLockoutDateUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lockoutDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLockoutDateUserDefaultsKey];
}

- (void)setBackgroundedDate:(NSDate *)backgroundedDate {
    [[NSUserDefaults standardUserDefaults] setObject:backgroundedDate forKey:kEnterBackgroundDateUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)backgroundedDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEnterBackgroundDateUserDefaultsKey];
}

@end
