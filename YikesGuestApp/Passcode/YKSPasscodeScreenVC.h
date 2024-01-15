//
//  YKSLockScreenVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/17/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import PKAlertController;
@import Fabric;
@import Crashlytics;
@import YikesGenericEngine;
@import SAMKeychain;
@import MMDrawerController;

typedef NS_ENUM(NSUInteger, YKSPasscodeViewMode) {
    kYKSPasscodeViewModeNone,
    kYKSPasscodeViewModeCreate,
    kYKSPasscodeViewModeUnlock,
    kYKSPasscodeViewModeChange,
    kYKSPasscodeViewModeDelete
};

typedef NS_ENUM(NSUInteger, kTouchIDFailure) {
    kTouchIDFailureIncorrectFingerprint,
    kTouchIDFailureUsePasscode,
    kTouchIDFailureCancel,
    kTouchIDFailureNoTouchID
};

@protocol YKSPasscodeScreenVCDelegate;

@interface YKSPasscodeScreenVC : UIViewController

@property (nonatomic) YKSPasscodeViewMode mode;

@property (weak, nonatomic) IBOutlet UILabel * titleLabel;
@property (weak, nonatomic) IBOutlet UILabel * timeLeftLabel;
@property (weak, nonatomic) IBOutlet UIView * passcodeCirclesView;
@property (weak, nonatomic) IBOutlet UIButton * cancelButton;
@property (weak, nonatomic) IBOutlet UIButton * deleteButton;

@property (weak, nonatomic) IBOutlet UIButton * forgotPasscodeButton;

@property (nonatomic, weak) id<YKSPasscodeScreenVCDelegate> delegate;

+ (YKSPasscodeScreenVC *)passcodeScreenWithMode:(YKSPasscodeViewMode)mode;
+ (BOOL)isPasscodeSet;
+ (void)resetPasscode;
+ (BOOL)userHasTouchID;

- (void)presentOverViewController:(UIViewController *)viewController;
- (void)dismiss;
- (void)endLockout;

@end

@protocol YKSPasscodeScreenVCDelegate <NSObject>

@optional
- (void)successfullyCreatedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;
- (void)successfullyChangedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;
- (void)successfullyDeletedPasscodeForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;

- (void)unlockWasSuccessfulForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;
- (void)unlockWasUnsuccessfulForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;

- (void)passcodeEntryWasCancelledForPasscodeScreenVC:(YKSPasscodeScreenVC *)passcodeScreenVC;

@end
