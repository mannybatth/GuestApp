//
//  YKSUtilities.m
//  YikesGuestApp
//
//  Created by Alexandar Dimitrov on 2015-07-31.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSUtilities.h"
#import "Colours.h"

@implementation YKSUtilities

+ (void) hideShowApiLabel:(UILabel *)envLabel {
    
    if ([[YikesEngine sharedEngine] currentApiEnv] == kYKSEnvDEV) {
        [envLabel setText:@"DEV"];
        [envLabel setHidden:NO];
        [envLabel setTextColor:[UIColor midnightBlueColor]];
    }
    else if ([[YikesEngine sharedEngine] currentApiEnv] == kYKSEnvQA) {
        [envLabel setText:@"QA"];
        [envLabel setHidden:NO];
        [envLabel setTextColor:[UIColor infoBlueColor]];
    }
    else {
        [envLabel setText:@""];
        [envLabel setHidden:YES];
    }
}

// Method created so it can be called from Swift and create an alert
// (Swift still can't call Obj-C macros)
+ (void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message inViewController:(UIViewController *) vc {
    PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
        
        configuration.title = title;
        configuration.message = message;
        configuration.presentationTransitionStyle = PKAlertControllerPresentationTransitionStyleFocusIn;
        
        NSMutableArray *actions = [NSMutableArray array];
        [actions addObject:[PKAlertAction okAction]];
        [configuration addActions:actions];
    }];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
