//
//  NSString+YKSString.m
//  YikesGuestApp
//
//  Created by Alexandar Dimitrov on 2016-02-15.
//  Copyright © 2016 yikes. All rights reserved.
//

#import "NSString+YKSString.h"

@implementation NSString (YKSString)

#pragma makr - validation methods

//TODO: Move to NSString Category

+ (BOOL) isStringEmpty:(NSString*)string {
    return [string isEqualToString:@""];
}


+ (BOOL) isValidEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}


+ (BOOL) doString:(NSString*) stringOne andStringMatch:(NSString*) stringTwo {
    
    if (stringOne && stringTwo && [stringOne isEqualToString:stringTwo]) {
        return YES;
    }
    else {
        return NO;
    }
}


//strips all non-numeric characters and checks that there are exactly numDigits characters
+ (BOOL)doesString:(NSString *)string containExactNumberOfDigits:(NSUInteger)numDigits {
    
    NSCharacterSet *nonNumericChars = [[NSCharacterSet
                                        characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    NSString * onlyNumbers = [[string componentsSeparatedByCharactersInSet:nonNumericChars ]
                              componentsJoinedByString:@""];
    
    if (onlyNumbers.length == numDigits) {
        return YES;
    }
    else {
        return NO;
    }
}


+ (BOOL)doesString:(NSString *)string containAtLeastNumberOfDigits:(NSUInteger)numDigits {
    
    NSCharacterSet *nonNumericChars = [[NSCharacterSet
                                        characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    NSString * onlyNumbers = [[string componentsSeparatedByCharactersInSet:nonNumericChars ]
                              componentsJoinedByString:@""];
    
    if (onlyNumbers.length >= numDigits) {
        return YES;
    }
    else {
        return NO;
    }
}


+ (NSString*)removeAnyCharOtherThanNumberFromString:(NSString*)string {
    NSCharacterSet *nonNumericChars = [[NSCharacterSet
                                        characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    return [[string componentsSeparatedByCharactersInSet:nonNumericChars ]
            componentsJoinedByString:@""];
}


+ (BOOL)doesString:(NSString *)string hasLengthAtLeast:(NSUInteger)numChars {
    return numChars <= [string length];
}

+ (NSString*)formatMobilePhoneNumberNorthAmerican:(NSString*)phoneNumber {
    
    NSMutableString* onlyNumbersPhone =
    [[self removeAnyCharOtherThanNumberFromString:phoneNumber] mutableCopy];
    
    if ([self doesString:onlyNumbersPhone containExactNumberOfDigits:4]) {
        [onlyNumbersPhone insertString:@"(" atIndex:0];
        [onlyNumbersPhone insertString:@") " atIndex:4];
        
        return onlyNumbersPhone;
    }
    
    if ([self doesString:onlyNumbersPhone containExactNumberOfDigits:7]) {
        [onlyNumbersPhone insertString:@"(" atIndex:0];
        [onlyNumbersPhone insertString:@") " atIndex:4];
        [onlyNumbersPhone insertString:@" " atIndex:9];
        
        return onlyNumbersPhone;
    }
    
    if ([self doesString:onlyNumbersPhone containAtLeastNumberOfDigits:10]) {
        onlyNumbersPhone = [[onlyNumbersPhone substringToIndex:10] mutableCopy];
        [onlyNumbersPhone insertString:@"(" atIndex:0];
        [onlyNumbersPhone insertString:@") " atIndex:4];
        [onlyNumbersPhone insertString:@" " atIndex:9];
        
        return onlyNumbersPhone;
    }
    
    return phoneNumber;
}


/* Password requirements:
 
 Minimum length: 8 characters
 Must include lower-case letters, upper-case letters and numbers
 Must include symbols "!@#$%^&*" (more secure but more annoying to the user)
 
 From: https:yikesdev.atlassian.net/wiki/display/AD/Password+Requirements?src=search
 
 */

+ (BOOL)doesStringContainLowerAndUpperCaseLetters:(NSString *)string{
    
    NSCharacterSet * uppercase = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    NSCharacterSet * lowercase = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz"];
    
    if ([string rangeOfCharacterFromSet:uppercase].location == NSNotFound) {
        return NO;
    }
    
    if ([string rangeOfCharacterFromSet:lowercase].location == NSNotFound) {
        return NO;
    }
    
    return YES;
}


+ (BOOL)doesStringContainANumber:(NSString *)string {
    NSCharacterSet * numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    if ([string rangeOfCharacterFromSet:numbers].location == NSNotFound) {
        return NO;
    }
    else {
        return YES;
    }
}


@end
