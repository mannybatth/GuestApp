//
//  YKSAddressInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 5/28/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAddressInfo.h"
#import "YKSConstants.h"

@interface YKSAddressInfo()

@property (nonatomic, strong, readwrite) NSString * addressLine1;
@property (nonatomic, strong, readwrite) NSString * addressLine2;
@property (nonatomic, strong, readwrite) NSString * addressLine3;
@property (nonatomic, strong, readwrite) NSString * city;
@property (nonatomic, strong, readwrite) NSString * country;
@property (nonatomic, strong, readwrite) NSString * postalCode;
@property (nonatomic, strong, readwrite) NSString * stateCode;

@end

@implementation YKSAddressInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSAddressInfo alloc] initWithJSONDictionary:dictionary];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.addressLine1 = NILIFNULL(dictionary[@"address_line_1"]);
    self.addressLine2 = NILIFNULL(dictionary[@"address_line_2"]);
    self.addressLine3 = NILIFNULL(dictionary[@"address_line_3"]);
    self.city = NILIFNULL(dictionary[@"city"]);
    self.country = NILIFNULL(dictionary[@"country"]);
    self.postalCode = NILIFNULL(dictionary[@"postal_code"]);
    self.stateCode = NILIFNULL(dictionary[@"state_code"]);
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Address: %@ %@ %@, City: %@, Country: %@, Postal Code: %@, State Code: %@",
            self.addressLine1,
            self.addressLine2,
            self.addressLine3,
            self.city,
            self.country,
            self.postalCode,
            self.stateCode];
}

@end
