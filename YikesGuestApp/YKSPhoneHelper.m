//
//  YKSPhoneHelper.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-09.
//
//

#import "YKSPhoneHelper.h"
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumberUtil.h"
#import "NBMetadataHelper.h"

@interface YKSPhoneHelper ()

@property (strong, nonatomic) NBAsYouTypeFormatter * typeFormatter;
@property (strong, nonatomic) NBPhoneNumberUtil * phoneUtil;
@property (strong, nonatomic) NBMetadataHelper *metadataHelper;
@property (copy) NSString * regionCode;

@end

@implementation YKSPhoneHelper

-(instancetype)initWithRegionCode:(NSString *)regionCode{
   
    self = [super init];
    if (self) {
        
        _typeFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:regionCode];
        _regionCode = regionCode;
        _phoneUtil = [[NBPhoneNumberUtil alloc] init];
        _metadataHelper = [[NBMetadataHelper alloc] init];
        
    }
    
    return self;
    
}

-(NSString *)formatNumber:(NSString *)number {
 
    NSString * numbersOnly = [[number componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789+"] invertedSet]] componentsJoinedByString:@""];
    [self.typeFormatter clear];
   return [self.typeFormatter inputString:numbersOnly];
    
}

-(BOOL)isValidPhoneNumber:(NSString *)number {
 
    //TODO: return NO if there's an error
    NSError * error;
    NBPhoneNumber * parsedNumber = [self.phoneUtil parse:number defaultRegion:self.regionCode error:&error];
    
    return [self.phoneUtil isValidNumber:parsedNumber];
    
    
}

-(NSString *)phoneCodeForCountryCode:(NSString *)countryCode {
   
    return [_metadataHelper countryCodeFromRegionCode:countryCode];
    
}

+ (NSString *)phoneWithSeperatorsForNumber:(NSString *)phoneNumber {
    
    NSMutableString *numberStr = [NSMutableString stringWithString:phoneNumber];
    
    int len = (int)[numberStr length];
    
    // add a dot before the 4th character from the right
    int n = 4;
    for (int i = len-1; i >= 0; i--) {
        
        n--;
        if (n == 0) {
            // add a dot when we are not on the first character
            if (i != 0) [numberStr insertString:@"." atIndex:i];
            
            // add a dot before the 3th character from the current index
            n = 3;
        }
        
    }
    
    return numberStr;
}

@end
