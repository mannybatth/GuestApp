//
//  YKSLoginVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSLoginVC.h"
#import "YKSCountryPicker.h"
@import YikesSharedModel;
@import OnePasswordExtension;

@interface YKSLoginVC () <UITextFieldDelegate>

@property (nonatomic, strong) UIImage * greenImage;
@property (nonatomic, strong) UIImage * whiteImage;

@property (weak, nonatomic) IBOutlet UIButton * onepasswordButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * passwordTextFieldTrailingSpaceToSuperView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * horizontalSpaceBetweenPasswordTFAnd1PasswordButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * emailTextFieldTrailingSpaceToSuperView;

@property (nonatomic, assign) BOOL didSignInUsing1Password;

@end

@implementation YKSLoginVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Switch API buttons set up
    CGFloat sizeCapInset = 10;
    self.greenImage = [UIImage imageNamed:@"greenbutton"];
    self.whiteImage = [UIImage imageNamed:@"button-white"];
    
    self.greenImage = [self.greenImage resizableImageWithCapInsets:UIEdgeInsetsMake(sizeCapInset, sizeCapInset, sizeCapInset, sizeCapInset)];
    self.whiteImage = [self.whiteImage resizableImageWithCapInsets:UIEdgeInsetsMake(sizeCapInset, sizeCapInset, sizeCapInset, sizeCapInset)];
    
    [self.devApiButton setContentMode:UIViewContentModeScaleToFill];
    [self.qaApiButton setContentMode:UIViewContentModeScaleToFill];
    [self.prodApiButton setContentMode:UIViewContentModeScaleToFill];
    
    [self setFonts];
    
    _emailTextField.delegate = self;
    _passwordTextfield.delegate = self;
    
    // when showing the login, we shouldn't be receiving push notifications:
    [self unregisterForPushNotificationsIfRegistered];
    
    self.emailTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"guest_email"];
    [self showHidePasswordButton];
    
#if DEBUG
    if ([self.emailTextField.text isEqualToString:@"test@yamm.ca"]) {
        self.passwordTextfield.text = @"Y@mm159!";
    }
#endif
    
    // Target actions to move view when keyboard is shown
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hudWillDisappear:)
                                                 name:SVProgressHUDWillDisappearNotification object:nil];
    
    YKSUserInfo *userInfo = [YikesEngine sharedInstance].userInfo;
    
    // redirect to EULA if it wasn't accepted yet
    if (userInfo) {
        
        BOOL userAcceptedEULA = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"EULAacceptedAlready_userid%@", userInfo.userId]];
        
        if (!userAcceptedEULA) {
            [[YikesEngine sharedInstance] pauseEngine];
            [self presentEULAScreen];
        }
        else {
            [[YikesEngine sharedInstance] userAcceptedEULA:userInfo.email];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    [self prepareControlsBasedOnEmailEntered];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, -((self.view.frame.size.height - self.scrollView.frame.size.height) + self.scrollView.frame.origin.y), 0.0f);
}

- (void)unregisterForPushNotificationsIfRegistered {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            [[AppManager sharedInstance] unregisterForPushNotifications];
        }
    }
    else {
        [[AppManager sharedInstance] unregisterForPushNotifications];
    }
}

- (void)setFonts {
    
    self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.emailTextField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.passwordTextfield.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.passwordTextfield.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
}


- (void)prepareControlsBasedOnEmailEntered {
    
    [self hideAllAPIButtons];
    
    NSString *email = self.emailTextField.text;
    
    if (email.length > 0 &&
        ([YKSDeveloperHelper isDevQaProdUser:email] || [YKSDeveloperHelper isQaProdUser:email])) {
        
        if ([YKSDeveloperHelper isDevQaProdUser:email]) {
            
            [self showAllAPIButtons];
            
        } else if ([YKSDeveloperHelper isQaProdUser:email]) {
            
            [self showOnlyQaAndProdButtons];
        }
        
    } else if ([[YikesEngine sharedInstance] currentApiEnv] == kYKSEnvDEV) {
        
        [self showAllAPIButtons];
    
    } else if ([[YikesEngine sharedInstance] currentApiEnv] == kYKSEnvQA) {
        
        [self showOnlyQaAndProdButtons];
    }
    
    [self prepareApiControls];
}

- (void)hideAllAPIButtons {
    self.devApiButton.hidden = YES;
    self.qaApiButton.hidden = YES;
    self.prodApiButton.hidden = YES;
    self.apiEnvironmentsView.hidden = YES;
    self.apiEnvironmentsViewHeightConstraint.constant = 0;
}

- (void)showAllAPIButtons {
    self.devApiButton.hidden = NO;
    self.qaApiButton.hidden = NO;
    self.prodApiButton.hidden = NO;
    self.apiEnvironmentsView.hidden = NO;
    self.apiEnvironmentsViewHeightConstraint.constant = 35;
}

- (void)showOnlyQaAndProdButtons {
    self.qaApiButton.hidden = NO;
    self.prodApiButton.hidden = NO;
    self.devApiButton.hidden = YES;
    self.apiEnvironmentsView.hidden = NO;
    self.apiEnvironmentsViewHeightConstraint.constant = 35;
}

- (void)prepareApiControls {
    
    switch ([YikesEngine sharedInstance].currentApiEnv) {
        case kYKSEnvDEV:
            [self setDevButtonActivated:YES];
            [self setQaButtonActivated:NO];
            [self setProdButtonActivated:NO];
            break;
            
        case kYKSEnvQA:
            [self setDevButtonActivated:NO];
            [self setQaButtonActivated:YES];
            [self setProdButtonActivated:NO];
            break;
            
        default:
            [self setDevButtonActivated:NO];
            [self setQaButtonActivated:NO];
            [self setProdButtonActivated:YES];
            break;
    }
}

- (void)setDevButtonActivated:(BOOL)isActivated {
    
    if (isActivated) {
        [self.devApiButton setBackgroundImage:self.greenImage forState:UIControlStateNormal];
        [self.devApiButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self.devApiButton setBackgroundImage:self.whiteImage forState:UIControlStateNormal];
        [self.devApiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

- (void)setQaButtonActivated:(BOOL)isActivated {
    
    if (isActivated) {
        [self.qaApiButton setBackgroundImage:self.greenImage forState:UIControlStateNormal];
        [self.qaApiButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self.qaApiButton setBackgroundImage:self.whiteImage forState:UIControlStateNormal];
        [self.qaApiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

- (void)setProdButtonActivated:(BOOL)isActivated {
    if (isActivated) {
        [self.prodApiButton setBackgroundImage:self.greenImage forState:UIControlStateNormal];
        [self.prodApiButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self.prodApiButton setBackgroundImage:self.whiteImage forState:UIControlStateNormal];
        [self.prodApiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

- (IBAction)pressDevButton:(id)sender {
    [self changeAPI:kYKSEnvDEV withMessage:YES];
}


- (IBAction)pressQaButton:(id)sender {
    [self changeAPI:kYKSEnvQA withMessage:YES];
}


- (IBAction)pressProdButton:(id)sender {
    [self changeAPI:kYKSEnvPROD withMessage:YES];
}

- (void)changeAPI:(NSInteger)apiValue withMessage:(BOOL)shouldMessage {
    
    CLS_LOG(@"Current API Env value is: %li", (long)apiValue);
    
    [[YikesEngine sharedInstance] stopEngineWithSuccess:nil];
    
    BOOL wasApiChanged = [[YikesEngine sharedInstance] changeCurrentApiEnv:apiValue];
    
    if (shouldMessage) {
        
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (apiValue == kYKSEnvDEV) {
            
            [[YikesEngine sharedInstance] setDebugMode:YES];
            
            if (wasApiChanged) {
                [SVProgressHUD showSuccessWithStatus:@"Switched to DEV API"];
            }
            else {
                [SVProgressHUD showErrorWithStatus:@"Could not switch to DEV API!\nEngine is ON"];
            }
            
        } else if (apiValue == kYKSEnvQA) {
            
            [[YikesEngine sharedInstance] setDebugMode:YES];
            
            if (wasApiChanged) {
                [SVProgressHUD showSuccessWithStatus:@"Switched to QA API"];
            }
            else {
                [SVProgressHUD showErrorWithStatus:@"Could not switch to QA API!\nEngine is ON"];
            }

        } else {
            
            if (wasApiChanged) {
                [SVProgressHUD showSuccessWithStatus:@"Switched to PROD API"];
            }
            else {
                [SVProgressHUD showErrorWithStatus:@"Could not switch to PROD API!\nEngine is ON"];
            }
        }
    }
    
    [self prepareApiControls];
}

- (void)presentEULAScreen {
    UIStoryboard * main = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *licenseAgreementVC = [main instantiateViewControllerWithIdentifier:@"YKSLicenseAgreementVC"];
    [self.navigationController pushViewController:licenseAgreementVC animated:YES];
}


- (void)presentResetPasswordScreenWithSuccess: (void(^)(void))success
    andFailure: (void(^)(void))failure {

    UIStoryboard *login = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    YKSTemporaryPwdVC *resetPwdVC = [login instantiateViewControllerWithIdentifier:@"YKSSetPasswordSID"];
    resetPwdVC.currentPassword = self.passwordTextfield.text;
    
    resetPwdVC.successBlock = success;
    resetPwdVC.failureBlock = failure;
    
    [self.navigationController pushViewController:resetPwdVC animated:YES];
}


- (void)attemptSignIn {
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextfield.text;
    if (!email.length) {
        [SVProgressHUD showErrorWithStatus:@"Email is required"];
        [_emailTextField becomeFirstResponder];
        return;
    }
    if (!password.length) {
        [SVProgressHUD showErrorWithStatus:@"Password is required"];
        [_passwordTextfield becomeFirstResponder];
        return;
    }
    
    if (![YKSDeveloperHelper isDevQaProdUser:email] &&
        ![YKSDeveloperHelper isQaProdUser:email]) {
        [self changeAPI:kYKSEnvPROD withMessage:NO];
    }
    else {
        [[YikesEngine sharedInstance] setDebugMode:YES];
    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:@"Signing in..."];
    
    [[YikesEngine sharedInstance] startEngineWithUsername:email
                                               password:password
                                           requiresEULA:YES
                                                success:^(YKSUserInfo *user)
     {
         CLS_LOG(@"Successfully started engine. UserInfo: %@", user);
         
         [SVProgressHUD dismiss];
         
         [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"guest_email"];
         
         // Fabric & Crashlytics stuff:
         [[AppManager sharedInstance] setFabricUserInfo];
         
         [Answers logLoginWithMethod:self.didSignInUsing1Password? @"1Password" : @"Typing"
                             success:@YES
                    customAttributes:@{@"username": email,
                                       @"yCentral Environment": @([YikesEngine sharedInstance].currentApiEnv).stringValue
                                       }];
         
         
         if (user.hasTempPassword) {
             [[YikesEngine sharedInstance] pauseEngine];
             
             [self presentResetPasswordScreenWithSuccess:^{
                 [self reviewEULA:user];
             } andFailure:^{
                 [AppDelegate goToLoginView];
             }];
         }
         else {
             [self reviewEULA:user];
         }
         
     } failure:^(YKSError *error) {
         
         [[YikesEngine sharedInstance] stopEngineWithSuccess:nil];
         
         CLS_LOG(@"Failed to start engine. %@", error);
         
         [[YikesEngine sharedInstance] stopEngineWithSuccess:nil];
         
         [Answers logLoginWithMethod:self.didSignInUsing1Password? @"1Password" : @"Typing" success:@NO customAttributes:@{@"username": email,
             @"yCentral Environment": @([YikesEngine sharedInstance].currentApiEnv).stringValue
         }];
         
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hudTapped:) name:SVProgressHUDDidReceiveTouchEventNotification object:nil];
         
         NSLog(@"%@", error);
         if (error.errorCode == kYKSUserNotAuthorized) {
             [SVProgressHUD showErrorWithStatus:@"Invalid Login\n\nYour email address and password combination is incorrect"];
         } else {
             [SVProgressHUD showErrorWithStatus:@"Network Error\n\nCould not connect to the server.\n Please verify your internet connection and try again."];
         }
         
     }];
}

- (void)reviewEULA:(YKSUserInfo*)user {
    
    BOOL EULAacceptedAlready = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"EULAacceptedAlready_userid%@", user.userId]];
    
    if (!EULAacceptedAlready) {
        [self presentEULAScreen];
    }
    else {
        [[YikesEngine sharedInstance] userAcceptedEULA:user.email];
        // Engine is resumed in that call:
        [AppDelegate goToViewAfterLogin];
    }
}

- (IBAction)signinPressed
{
    [self.view endEditing:YES];
    [self attemptSignIn];
}

- (IBAction)bgTap:(id)sender {
    [self.view endEditing:YES];
}

#pragma mark - view reposition with keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat difference = ((self.view.frame.size.height - self.scrollView.frame.size.height) - self.scrollView.frame.origin.y);
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height)-difference, 0.0);
    CGPoint contentOffset = CGPointZero;
    
    UITextField *activeField;
    if ([self.emailTextField isFirstResponder]) {
        activeField = self.emailTextField;
    } else {
        activeField = self.passwordTextfield;
    }
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    
    CGFloat padding = activeField.frame.size.height + 25.0f;
    
    CGPoint activePoint = activeField.frame.origin;
    activePoint.y += padding;
    
    if (!CGRectContainsPoint(aRect, activePoint)) {
        contentOffset = CGPointMake(0.0, padding);
    }
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.scrollView.contentInset = contentInsets;
        self.scrollView.scrollIndicatorInsets = contentInsets;
        if (!CGPointEqualToPoint(contentOffset, CGPointZero)) {
            [self.scrollView setContentOffset:contentOffset animated:NO];
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    CGFloat difference = ((self.view.frame.size.height - self.scrollView.frame.size.height) + self.scrollView.frame.origin.y);
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, -difference, 0.0f);
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

#pragma mark - Optional features

- (void)showHidePasswordButton {
    
    // warning: this won't work in iOS 9 unless the URL used in canOpenURL: is white listed.
    BOOL isOnePasswordExtensionAvailable = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    
    if (!isOnePasswordExtensionAvailable) {
        [self.onepasswordButton setHidden:YES];
        
        [[self.passwordTextfield superview] removeConstraint:self.horizontalSpaceBetweenPasswordTFAnd1PasswordButton];
        
        // iOS 7 incompatible:
//        [self.horizontalSpaceBetweenPasswordTFAnd1PasswordButton setActive:NO];
        
        self.passwordTextfield.frame = self.emailTextField.frame;
        CGFloat constantValue = self.emailTextFieldTrailingSpaceToSuperView.constant;
        self.passwordTextFieldTrailingSpaceToSuperView.constant = constantValue;
    }
}

#pragma mark - 1Password actions
- (IBAction)findLoginFrom1Password:(id)sender {
    
    [self.view endEditing:YES];
    
    [[OnePasswordExtension sharedExtension]
     findLoginForURLString:@"https://guest.yikes.co" forViewController:self sender:sender completion:^(NSDictionary *loginDictionary, NSError *error) {
         
         if (!loginDictionary || loginDictionary.count == 0) {
             return;
         }
         
         NSString *username = loginDictionary[AppExtensionUsernameKey];
         
         self.emailTextField.text = username;
         self.passwordTextfield.text = loginDictionary[AppExtensionPasswordKey];
         
         self.didSignInUsing1Password = YES;
         
         [self prepareControlsBasedOnEmailEntered];
         
         if ([YKSDeveloperHelper isDevQaProdUser:username] ||
             [YKSDeveloperHelper isQaProdUser:username]) {
             
             return;
         }
         
         [self signinPressed];
     }];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == _emailTextField) {
        [_passwordTextfield becomeFirstResponder];
    
    } else {
        [textField resignFirstResponder];
        [self signinPressed];
    }
    
    return YES;
}

#pragma mark -

- (IBAction)emailEditingChanged:(id)sender {
    
    [self prepareControlsBasedOnEmailEntered];
    
    // edited manually, assume not using 1Password
    self.didSignInUsing1Password = NO;
}

- (IBAction)passwordEditingChanged:(id)sender {
    
    // edited manually, assume not using 1Password
    self.didSignInUsing1Password = NO;
}

- (void)hudTapped:(NSNotification *)notification {
    NSLog(@"HUD tapped!");
    [SVProgressHUD dismiss];
}

- (void)hudWillDisappear:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"forgotPasswordSID"]) {
        NSString *email = self.emailTextField.text;
        if ([NSString isValidEmail:email]) {
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"guest_email"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SVProgressHUDWillDisappearNotification object:nil];
}

@end
