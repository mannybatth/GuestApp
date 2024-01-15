//
//  YKSTestAccounts.m
//  yikes
//
//  Created by Andy Shephard on 2014-10-22.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "YKSTestAccounts.h"
@interface YKSTestAccounts()
@property (nonatomic, strong) NSArray *testAccounts;
@end

@implementation YKSTestAccounts

+ (BOOL)isTestUser:(NSString *)email
{
    
    NSRange rYikes = [email rangeOfString:@"@yikes.co"];
    if (rYikes.location != NSNotFound) {
        return YES;
    }
    
    NSRange rYamm = [email rangeOfString:@"@yamm.ca"];
    if (rYamm.location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

@end
