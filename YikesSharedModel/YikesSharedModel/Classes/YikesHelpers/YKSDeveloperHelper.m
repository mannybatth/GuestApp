//
//  YKSDeveloperHelper.m
//  YikesSharedModel
//
//  Created by Alexandar Dimitrov on 2016-08-31.
//  Copyright © 2016 Yikes. All rights reserved.
//

#import "YKSDeveloperHelper.h"

@implementation YKSDeveloperHelper

// Domains and users who have access to DEV, QA and PROD envs
+ (BOOL) isDevQaProdUser: (NSString*) email
{
    NSRange rYamm = [email rangeOfString:@"@yamm.ca"];
    if (rYamm.location != NSNotFound) {
        return YES;
    }
    
    // Yikes Hotel
    NSRange rYikesHotel = [email rangeOfString:@"hotel@yikes.co"];
    if (rYikesHotel.location != NSNotFound) {
        return YES;
    }
    
    // Richard Moore
    NSRange rRichardMoore = [email rangeOfString:@"richardm@yikes.co"];
    if (rRichardMoore.location != NSNotFound) {
        return YES;
    }
    
    // Bob Maccione
    NSRange rBobMaccione = [email rangeOfString:@"bobm@yikes.co"];
    if (rBobMaccione.location != NSNotFound) {
        return YES;
    }
    
    // Manny
    NSRange rMannySingh = [email rangeOfString:@"manny.singh@yikes.co"];
    if (rMannySingh.location != NSNotFound) {
        return YES;
    }
    
    // Alexandar Dimitrov
    NSRange rAlexDimitrov = [email rangeOfString:@"alexandar.dimitrov@yikes.co"];
    if (rAlexDimitrov.location != NSNotFound) {
        return YES;
    }
    
    // Chad Coons
    NSRange rChadCoons = [email rangeOfString:@"chad.coons@yikes.co"];
    if (rChadCoons.location != NSNotFound) {
        return YES;
    }
    
    // Javier
    NSRange rJavierAndalia = [email rangeOfString:@"javier.andalia@yikes.co"];
    if (rJavierAndalia.location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

// Domains and users who have access to QA and PROD envs only
+ (BOOL) isQaProdUser: (NSString*) email {
    NSRange rYikes = [email rangeOfString:@"@yikes.co"];
    if (rYikes.location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

@end
