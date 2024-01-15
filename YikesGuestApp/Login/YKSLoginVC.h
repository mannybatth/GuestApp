//
//  YKSLoginVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSLoginVC : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView * scrollView;
@property (weak, nonatomic) IBOutlet UITextField * emailTextField;
@property (weak, nonatomic) IBOutlet UITextField * passwordTextfield;

@property (weak, nonatomic) IBOutlet UIButton * signInButton;
@property (weak, nonatomic) IBOutlet UIButton * helpButton;

@property (weak, nonatomic) IBOutlet UIButton * devApiButton;
@property (weak, nonatomic) IBOutlet UIButton * qaApiButton;
@property (weak, nonatomic) IBOutlet UIButton * prodApiButton;

@property (weak, nonatomic) IBOutlet UIView * apiEnvironmentsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * apiEnvironmentsViewHeightConstraint;

- (IBAction)signinPressed;

@end
