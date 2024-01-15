//
//  PKAlertYikesTheme.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/26/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "PKAlertYikesTheme.h"
@import HexColors;

@implementation PKAlertYikesTheme

- (UIColor *)mainColor
{
    return [UIColor whiteColor];
}

- (UIColor *)baseTintColor {
    return [UIColor colorWithWhite:1 alpha:1];
}

- (UIColor *)barTintColor {
    return [UIColor colorWithHexString:@"5F9318" alpha:0.90];
}

- (UIColor *)highlightColor {
    return [[self barTintColor] colorWithAlphaComponent:1.0];
}

- (UIColor *)backgroundColor {
    return [UIColor whiteColor];
}

- (UIColor *)separatorColor {
    return [UIColor colorWithHexString:@"49750E" alpha:1.0];
}

@end
