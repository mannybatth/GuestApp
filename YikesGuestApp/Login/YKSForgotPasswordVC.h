//
//  YKSForgotPasswordVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/23/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import YikesGenericEngine;
@import SVProgressHUD;

@interface YKSForgotPasswordVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *apiEnvLabel;

@property (weak, nonatomic) IBOutlet UITextField * emailTextField;

@end
