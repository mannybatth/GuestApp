//
//  YKSSignUpCompleted.h
//  yikes
//
//  Created by Alexandar Dimitrov on 2014-11-12.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YKSUIModuleSignup;

@interface YKSSignUpCompleted : UIViewController

@property (nonatomic, strong) NSString* firstName;
@property (nonatomic, strong) NSString* lastName;
@property (nonatomic, strong) NSString* email;
@property (strong, nonatomic) IBOutlet UIView *registrationView;

@property (nonatomic, copy) void (^callback)();

@end
