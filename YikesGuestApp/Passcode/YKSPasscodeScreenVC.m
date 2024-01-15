//
//  YKSLockScreenVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/17/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSPasscodeScreenVC.h"
#import "YKSPasscodeCircleView.h"
#import "ABPadButton.h"

@import SAMKeychain;

#if __IPHONE_8_0
#import <LocalAuthentication/LocalAuthentication.h>
#endif

// Error Codes for Touch ID Implementation
#define kTouchIDErrorIncorrectFingerprint -1
#define kTouchIDErrorCancel               -2
#define kTouchIDErrorUsePassword          -3

static NSString *kPasscodeServiceName = @"pincode";
static NSString *kPasscodeAccountName = @"user";

///@brief The number of attempts the user has to enter their passcode correctly.
static int kPasscodeMaxAttempts = 5;

///@brief The length of the passcode. Default is typically 4.
static int kPasscodeLength = 4;

@interface YKSPasscodeScreenVC ()

@property (nonatomic) int attemptsLeft;

@property (nonatomic, strong) NSMutableString *inputSequence;
@property (nonatomic, strong) NSMutableString *oldPasscodeCheckInputSequence;
@property (nonatomic, strong) NSMutableString *inputVerifySequence;

@property (nonatomic) BOOL isVerifying;
@property (nonatomic) BOOL oldPasscodeCheckPassed;

@property (nonatomic, strong) NSTimer *lockoutTimeLeftTimer;

@end

@implementation YKSPasscodeScreenVC

+ (YKSPasscodeScreenVC *)passcodeScreenWithMode:(YKSPasscodeViewMode)mode {
    
    YKSPasscodeScreenVC *passcodeScreenVC = [[YKSPasscodeScreenVC alloc] initWithNibName:@"YKSPasscodeScreenVC" bundle:nil];
    passcodeScreenVC.mode = mode;
    passcodeScreenVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    passcodeScreenVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return passcodeScreenVC;
    
}

- (void)presentOverViewController:(UIViewController *)viewController {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationLockScreenIsPresented object:nil];
    [viewController presentViewController:self animated:YES completion:nil];
}

- (void)dismiss {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationLockScreenIsDismissed object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"SAVED SEQUENCE: %@", [SAMKeychain passwordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]]);
    
    self.cancelButton.hidden = NO;
    self.forgotPasscodeButton.hidden = NO;
    self.attemptsLeft = kPasscodeMaxAttempts;
    
    switch (self.mode) {
        case kYKSPasscodeViewModeCreate:
            self.titleLabel.text = @"create passcode";
            self.forgotPasscodeButton.hidden = YES;
            break;
        case kYKSPasscodeViewModeUnlock:
            self.titleLabel.text = @"enter passcode";
            self.cancelButton.hidden = YES;
            break;
        case kYKSPasscodeViewModeChange:
            self.titleLabel.text = @"enter old passcode";
            break;
        case kYKSPasscodeViewModeDelete:
            self.titleLabel.text = @"enter passcode";
            break;
            
        default:
            break;
    }
    
    [self resetInput];
    
    if (YikesApplication.isLockedOut && self.mode == kYKSPasscodeViewModeUnlock) {
        [self lockoutScreen];
    }
    
    [self askForTouchID];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    
    [self updateLockoutTimeLeft];
    [self askForTouchID];
}

- (IBAction)pinButtonSelected:(ABPadButton *)sender {
    
    NSMutableString *sequence;
    [self pointToActiveSequence:&sequence];
    
    [sequence appendString:[NSString stringWithFormat:@"%lu", (unsigned long)sender.tag]];
    [self changeActiveSequenceTo:sequence];
    
}

- (IBAction)forgotPasscodeSelected:(id)sender {
    
    PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
        
        configuration.message = @"Are you sure you want to reset passcode & logout?";
        
        [configuration addAction:[PKAlertAction actionWithTitle:@"Yes" handler:^(PKAlertAction *action, BOOL closed) {
            
            if (closed) {
                [YKSPasscodeScreenVC resetPasscode];
                [self logout];
            }
            
        }]];
        
        [configuration addAction:[PKAlertAction cancelAction]];
        
    }];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)cancelButtonSelected:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(passcodeEntryWasCancelledForPasscodeScreenVC:)]) {
        [self.delegate passcodeEntryWasCancelledForPasscodeScreenVC:self];
    }
}

- (IBAction)deleteButtonSelected:(UIButton *)sender {
    
    NSMutableString *sequence;
    [self pointToActiveSequence:&sequence];
    
    if (sequence.length > 0) {
        [sequence deleteCharactersInRange:NSMakeRange([sequence length]-1, 1)];
        [self changeActiveSequenceTo:sequence];
    }
    
}

- (void)logout {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // Log before the logout to know about the user:
    [Answers logCustomEventWithName:@"Logout" customAttributes:@{@"username": [YikesEngine sharedEngine].userInfo.email,
                                                                 @"API Environment": [YikesEngine sharedEngine].currentApiEnvString}];
    
    [[YikesEngine sharedInstance] stopEngineWithSuccess:^{
        
    }];
    
    [AppDelegate goToLoginView];
    
}

- (void)pointToActiveSequence:(NSString **)sequence {
    
    if (self.mode == kYKSPasscodeViewModeChange && !self.oldPasscodeCheckPassed) {
        *sequence = self.oldPasscodeCheckInputSequence;
    } else {
        if (self.isVerifying) {
            *sequence = self.inputVerifySequence;
        } else {
            *sequence = self.inputSequence;
        }
    }
}

- (void)changeActiveSequenceTo:(NSString *)newSequence {
    
    NSMutableString *sequence;
    [self pointToActiveSequence:&sequence];
    
    sequence = [NSMutableString stringWithString:newSequence];
    [self fillCircleViewsForInputSequence:sequence];
    
    if (sequence.length >= kPasscodeLength) {
        [self processActiveSequence];
    }
    
}

- (void)processActiveSequence {
    
    switch (self.mode) {
        case kYKSPasscodeViewModeCreate:
            [self processPasscodeCreate];
            break;
        case kYKSPasscodeViewModeUnlock:
            [self processPasscodeUnlock];
            break;
        case kYKSPasscodeViewModeChange:
            [self processPasscodeChange];
            break;
        case kYKSPasscodeViewModeDelete:
            [self processPasscodeDelete];
            break;
            
        default:
            break;
    }
    
}

- (void)processPasscodeCreate {
    
    if (self.isVerifying) {
        
        if ([self.inputSequence isEqualToString:self.inputVerifySequence]) {
            [self createPasscodeWithSequence:(NSString *)self.inputSequence wasChanged:NO];
        } else {
            [self animateFailureNotification];
            [self resetVerifyInput];
        }
        
    } else {
        
        self.titleLabel.text = @"verify passcode";
        [self fillCircleViewsForInputSequence:@""];
        self.isVerifying = YES;
    }
    
}

- (void)processPasscodeUnlock {
    
    NSString *savedSequence = [SAMKeychain passwordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    if ([self.inputSequence isEqualToString:savedSequence]) {
        [self unlockPassed];
    } else {
        [self animateFailureNotification];
        [self failedAttemptOccurred];
        [self resetInput];
    }
    
}

- (void)processPasscodeChange {
    
    NSString *savedSequence = [SAMKeychain passwordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    if ([self.oldPasscodeCheckInputSequence isEqualToString:savedSequence]) {
        
        if (self.oldPasscodeCheckPassed) {
            
            if (self.isVerifying) {
                
                if ([self.inputSequence isEqualToString:self.inputVerifySequence]) {
                    [self createPasscodeWithSequence:(NSString *)self.inputSequence wasChanged:YES];
                } else {
                    [self animateFailureNotification];
                    [self resetVerifyInput];
                }
                
            } else {
                
                self.titleLabel.text = @"verify passcode";
                [self fillCircleViewsForInputSequence:@""];
                self.isVerifying = YES;
            }
            
        } else {
            
            self.titleLabel.text = @"new passcode";
            [self fillCircleViewsForInputSequence:@""];
        }
        self.oldPasscodeCheckPassed = YES;
        
    } else {
        
        [self animateFailureNotification];
        [self resetOldPasscodeCheckInput];
        
    }
    
}

- (void)processPasscodeDelete {
    
    NSString *savedSequence = [SAMKeychain passwordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    if ([self.inputSequence isEqualToString:savedSequence]) {
        [self deletePasscode];
    } else {
        [self animateFailureNotification];
        [self resetInput];
    }
    
}

- (void)failedAttemptOccurred {
    
    self.attemptsLeft--;
    if (self.attemptsLeft <= 0) {
        
        YikesApplication.isLockedOut = YES;
        [self lockoutScreen];
        
    }
}

- (void)lockoutScreen {
    
    if (YikesApplication.isLockedOut && self.mode == kYKSPasscodeViewModeUnlock) {
        self.titleLabel.text = @"App is locked!";
        self.timeLeftLabel.hidden = NO;
        self.passcodeCirclesView.hidden = YES;
        [self updateLockoutTimeLeft];
        [self startLockoutTimeLeftTimer];
        
        [self.view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)obj;
                button.enabled = NO;
            }
            
        }];
    }
}

- (void)updateLockoutTimeLeft {
    
    if (YikesApplication.lockoutDate) {
        int totalLockoutTime = kApplicationAppLockout;
        NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:YikesApplication.lockoutDate];
        int minutesLeft = ceil((totalLockoutTime-timeDifference)/60);
        self.timeLeftLabel.text = [NSString stringWithFormat:@"%i minute%@ left", minutesLeft, (minutesLeft != 1) ? @"s" : @""];
    }
}

- (void)startLockoutTimeLeftTimer {
    
    [self stopLockoutTimeLeftTimer];
    
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:date];
    
    NSTimeInterval timeSinceLastSecond = date.timeIntervalSince1970 - floor(date.timeIntervalSince1970);
    NSTimeInterval timeToNextMinute = (60 - dateComponents.second) - timeSinceLastSecond;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToNextMinute * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.lockoutTimeLeftTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateLockoutTimeLeft) userInfo:nil repeats:YES];
    });
}

- (void)stopLockoutTimeLeftTimer {
    
    if (self.lockoutTimeLeftTimer) {
        [self.lockoutTimeLeftTimer invalidate];
    }
    
    self.lockoutTimeLeftTimer = nil;
}

- (void)endLockout {
    
    if (!YikesApplication.isLockedOut && self.mode == kYKSPasscodeViewModeUnlock) {
        self.titleLabel.text = @"enter passcode";
        self.timeLeftLabel.hidden = YES;
        self.passcodeCirclesView.hidden = NO;
        [self.view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)obj;
                button.enabled = YES;
            }
            
        }];
        
        self.attemptsLeft = kPasscodeMaxAttempts;
        [self resetInput];
        [self stopLockoutTimeLeftTimer];
    }
}

- (void)fillCircleViewsForInputSequence:(NSString *)sequence {
    
    [self.passcodeCirclesView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       
        if ([obj isKindOfClass:[YKSPasscodeCircleView class]]) {
            
            YKSPasscodeCircleView *circleView = (YKSPasscodeCircleView *)obj;
            circleView.filled = NO;
            if (idx < sequence.length) {
                circleView.filled = YES;
            }
            
        }
        
    }];
    
    if (sequence.length > 0) {
        self.deleteButton.hidden = NO;
        self.cancelButton.hidden = YES;
    } else {
        self.deleteButton.hidden = YES;
        
        if (self.mode != kYKSPasscodeViewModeUnlock) {
            self.cancelButton.hidden = NO;
        }
    }
}

- (void)animateFailureNotification {
    [self animateFailureNotificationDirection:-35.0f];
}

- (void)animateFailureNotificationDirection:(CGFloat)direction {
    
    [UIView animateWithDuration:0.08 animations:^{
        
        CGAffineTransform transform = CGAffineTransformMakeTranslation(direction, 0);
        self.passcodeCirclesView.layer.affineTransform = transform;
        
    } completion:^(BOOL finished) {
        if (fabs(direction) < 1) {
            self.passcodeCirclesView.layer.affineTransform = CGAffineTransformIdentity;
            return;
        }
        [self animateFailureNotificationDirection:-1 * direction / 2];
    }];
}

- (void)unlockPassed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(unlockWasSuccessfulForPasscodeScreenVC:)]) {
        [self.delegate unlockWasSuccessfulForPasscodeScreenVC:self];
    }
}

- (void)unlockFailed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(unlockWasUnsuccessfulForPasscodeScreenVC:)]) {
        [self.delegate unlockWasUnsuccessfulForPasscodeScreenVC:self];
    }
}

- (void)createPasscodeWithSequence:(NSString *)sequence wasChanged:(BOOL)changed {
    
    [SAMKeychain setPassword:sequence forService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    
    if (changed) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(successfullyChangedPasscodeForPasscodeScreenVC:)]) {
            [self.delegate successfullyChangedPasscodeForPasscodeScreenVC:self];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(successfullyCreatedPasscodeForPasscodeScreenVC:)]) {
            [self.delegate successfullyCreatedPasscodeForPasscodeScreenVC:self];
        }
    }
}

- (void)deletePasscode {
    
    [SAMKeychain deletePasswordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(successfullyCreatedPasscodeForPasscodeScreenVC:)]) {
        [self.delegate successfullyDeletedPasscodeForPasscodeScreenVC:self];
    }
    
}

- (void)resetInput {
    self.inputSequence = [NSMutableString string];
    self.inputVerifySequence = [NSMutableString string];
    self.oldPasscodeCheckInputSequence = [NSMutableString string];
    [self fillCircleViewsForInputSequence:@""];
    self.isVerifying = NO;
}

- (void)resetVerifyInput {
    self.inputVerifySequence = [NSMutableString string];
    [self fillCircleViewsForInputSequence:@""];
}

- (void)resetOldPasscodeCheckInput {
    self.oldPasscodeCheckInputSequence = [NSMutableString string];
    [self fillCircleViewsForInputSequence:@""];
}

- (void)askForTouchID {
    
    BOOL isTouchIdEnabledInSettings = [[NSUserDefaults standardUserDefaults] boolForKey:@"passcodeTouchIdEnabled"];
    
    if (self.mode == kYKSPasscodeViewModeUnlock && !YikesApplication.isLockedOut && isTouchIdEnabledInSettings) {
        [self authenticateWithCallback:^(BOOL success, kTouchIDFailure failureMsg) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self fillCircleViewsForInputSequence:@"TOID"];
                    [self performSelector:@selector(unlockPassed) withObject:nil afterDelay:1.0f];
                });
            }
        }];
    }
}

- (void)authenticateWithCallback:(void(^)(BOOL success, kTouchIDFailure failureMsg))callback {
    
    if ([YKSPasscodeScreenVC userHasTouchID]) {
        [self showTouchIDAlertWithCallback:^(BOOL success, kTouchIDFailure failureMsg) {
            callback(success, failureMsg);
        }];
    } else {
        callback(NO, kTouchIDFailureNoTouchID);
    }
}

- (void)showTouchIDAlertWithCallback:(void(^)(BOOL success, kTouchIDFailure failureMsg))callback {
    
#if __IPHONE_8_0
    LAContext *localAuthenticationContext = [[LAContext alloc] init];
    
    if ([localAuthenticationContext respondsToSelector:@selector(touchIDAuthenticationAllowableReuseDuration)]) {
        [localAuthenticationContext setTouchIDAuthenticationAllowableReuseDuration:30];
    }
    
    __autoreleasing NSError *authenticationError;
    NSString *localizedReasonString =
    NSLocalizedString(@"Authenticate to unlock yikes app.",
                      @"String to prompt the user why we're using Touch ID.");
    
    if ([localAuthenticationContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                                error:&authenticationError]) {
        [localAuthenticationContext
         evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
         localizedReason:localizedReasonString
         reply:^(BOOL success, NSError *error) {
             
             if (success) {
                 
                 // Touch ID was a success, process login
                 callback(YES, -1);
                 
             } else {
                 
                 // Touch ID failed, check the code property on the error object
                 
                 kTouchIDFailure aFailure = kTouchIDFailureNoTouchID;
                 
                 switch ([error code]) {
                     case kTouchIDErrorIncorrectFingerprint:
                         aFailure = kTouchIDFailureIncorrectFingerprint;
                         CLS_LOG(@"Too many incorrect Touch ID attempts; Falling back to passcode entry");
                         break;
                     case kTouchIDErrorUsePassword:
                         aFailure = kTouchIDFailureUsePasscode;
                         CLS_LOG(@"User opted to enter password; Falling back to passcode entry");
                         break;
                     case kTouchIDErrorCancel:
                         aFailure = kTouchIDFailureCancel;
                         CLS_LOG(@"User pressed cancel; Falling back to passcode entry");
                         break;
                 }
                 
                 callback(NO, aFailure);
             }
         }];
    }
#endif
    
}

+ (BOOL)isPasscodeSet {
    NSString *sequence = [SAMKeychain passwordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
    if (sequence && sequence.length > 0) {
        return YES;
    }
    return NO;
}

+ (void)resetPasscode {
    [SAMKeychain deletePasswordForService:kPasscodeServiceName account:[YKSPasscodeScreenVC passcodeAccountName]];
}

+ (BOOL)userHasTouchID {
    
#if __IPHONE_8_0
    LAContext *localAuthenticationContext = [[LAContext alloc] init];
    __autoreleasing NSError *authenticationError;
    if ([localAuthenticationContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                                error:&authenticationError]) {
        return YES;
    } else {
        return NO;
    }
#endif
    
    return NO;
}

+ (NSString *)passcodeAccountName {
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    NSString *accountName = [NSString stringWithFormat:@"%@_%@", kPasscodeAccountName, user.deviceId];
    return accountName;
}

@end
