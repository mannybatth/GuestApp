//
//  YKSForgotPasswordVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSForgotPasswordVC.h"
#import "YKSUtilities.h"

@import YikesSharedModel;

@interface YKSForgotPasswordVC () <UITextFieldDelegate>

@end

@implementation YKSForgotPasswordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.emailTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    id guest_email = [[NSUserDefaults standardUserDefaults] objectForKey:@"guest_email"];
    if ([guest_email isKindOfClass:[NSString class]] && [NSString isValidEmail:guest_email]) {
        self.emailTextField.text = guest_email;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [YKSUtilities hideShowApiLabel:self.apiEnvLabel];
}

- (IBAction)resetPasswordPressed:(id)sender {
    
    NSString *email = self.emailTextField.text;
    
    if (email && [NSString isValidEmail:email]) {
        
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD showWithStatus:@"Submitting..."];
        
        [[YikesEngine sharedEngine] forgotPasswordForEmail:email success:^{
            
            [self.view endEditing:YES];
            [SVProgressHUD showSuccessWithStatus:@"Please check your email for instructions to reset your password."];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
            
        } failure:^(YKSError *error) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Error: %@", error.errorDescription]];
        }];
        
    } else {
        [SVProgressHUD showErrorWithStatus:@"Invalid email.\nPlease try again."];
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.emailTextField) {
        [self resetPasswordPressed:textField];
    }
    
    return YES;
}

- (IBAction)bgTap:(id)sender {
    [self.view endEditing:YES];
}

@end
