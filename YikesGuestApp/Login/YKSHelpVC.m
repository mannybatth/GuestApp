//
//  YKSHelpVC.m
//  yikes
//
//  Created by Andy Shephard on 2014-10-28.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "YKSHelpVC.h"
#import "YKSUtilities.h"

@import YikesSharedModel;

@interface YKSHelpVC () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;

@end

@implementation YKSHelpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appVersionLabel.text = [NSString stringWithFormat:@"VERSION %@", [AppManager fullVersionString]];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    [YKSUtilities hideShowApiLabel:self.envLabel];
}


- (IBAction)forgotPasswordTap:(id)sender {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Reset Password" message:@"Enter the e-mail address associated with your y!kes account. We'll e-mail instructions on how to reset your password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField* tf = [av textFieldAtIndex:0];
    tf.keyboardType = UIKeyboardTypeEmailAddress;
    tf.placeholder = @"Your e-mail address";
    
    [av show];
}

- (IBAction)watchWalkthroughTap:(id)sender {
    
    [AppDelegate goToWalkthrough];
}

#pragma mark - Orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        
        UITextField *tf = (id)[alertView textFieldAtIndex:0];
        NSString *email = tf.text;
        
        if (email && [NSString isValidEmail:email]) {
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD showWithStatus:@"Submitting..."];
            
            [[YikesEngine sharedEngine] forgotPasswordForEmail:email success:^{
                [SVProgressHUD showSuccessWithStatus:@"Please check your email for instructions to reset your password."];
            } failure:^(YKSError *error) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Error: %@", error.errorDescription]];
            }];
        }
        else {
            Alert(@"Error", @"Invalid email.\nPlease try again.");
        }
    }
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
