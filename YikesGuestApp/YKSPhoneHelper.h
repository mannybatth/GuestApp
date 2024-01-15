//
//  YKSPhoneHelper.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-09.
//
//

#import <Foundation/Foundation.h>

@protocol YKSPhoneHelperDelegate;

@interface YKSPhoneHelper : NSObject

-(instancetype)initWithRegionCode:(NSString *)regionCode;

-(NSString *)formatNumber:(NSString *)number;

-(BOOL)isValidPhoneNumber:(NSString *)number;

-(NSString *)phoneCodeForCountryCode:(NSString *)countryCode;

+ (NSString *)phoneWithSeperatorsForNumber:(NSString *)phoneNumber;

@end