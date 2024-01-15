//
//  NSString+YKSString.h
//  YikesGuestApp
//
//  Created by Alexandar Dimitrov on 2016-02-15.
//  Copyright © 2016 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (YKSString)

+ (BOOL)isStringEmpty:(NSString*)string;
+ (BOOL)isValidEmail: (NSString *) email;
+ (BOOL)doString:(NSString*) stringOne andStringMatch:(NSString*) stringTwo;
+ (BOOL)doesString:(NSString *)string containExactNumberOfDigits:(NSUInteger)numDigits;
+ (BOOL)doesString:(NSString *)string containAtLeastNumberOfDigits:(NSUInteger)numDigits;
+ (BOOL)doesString:(NSString *)string hasLengthAtLeast:(NSUInteger)numChars;
+ (BOOL)doesStringContainLowerAndUpperCaseLetters:(NSString *)string;
+ (BOOL)doesStringContainANumber:(NSString *)string;
+ (NSString*)removeAnyCharOtherThanNumberFromString:(NSString*)string;
+ (NSString*)formatMobilePhoneNumberNorthAmerican:(NSString*)phoneNumber;

@end
