//
//  YKSSignUpCompleted.m
//  yikes
//
//  Created by Alexandar Dimitrov on 2014-11-12.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "YKSSignUpCompleted.h"
@import YKSUIModuleSignup;

@interface YKSSignUpCompleted ()


@end

@implementation YKSSignUpCompleted

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.hidesBackButton = YES;
    
    CGRect signUpCompletedFrame = [UIApplication sharedApplication].keyWindow.frame;
    
    self.registrationView = [[YKSRegistrationReceived alloc] initWithFrame: signUpCompletedFrame
                                                                 firstName: self.firstName
                                                                  lastName: self.lastName
                                                                     email: self.email
                                                                  callback: self.callback];
    
    [self.view addSubview:self.registrationView];
}

#pragma mark - Orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 Get the new view controller using [segue destinationViewController].
 Pass the selected object to the new view controller.
 }
 */

@end
