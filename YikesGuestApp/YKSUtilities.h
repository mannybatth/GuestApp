//
//  YKSUtilities.h
//  YikesGuestApp
//
//  Created by Alexandar Dimitrov on 2015-07-31.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSUtilities : NSObject

+ (void) hideShowApiLabel:(UILabel *)envLabel;
+ (void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message inViewController:(UIViewController *) vc;

@end
