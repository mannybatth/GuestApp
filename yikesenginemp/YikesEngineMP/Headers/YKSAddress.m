//
//  YKSAddress.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAddress.h"

@implementation YKSAddress

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"addressLine1": @"address_line_1",
             @"addressLine2": @"address_line_2",
             @"addressLine3": @"address_line_3",
             @"city": @"city",
             @"country": @"country",
             @"postalCode": @"postal_code",
             @"stateCode": @"state_code",
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (YKSAddress *)newAddressFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSAddress.class fromJSONDictionary:JSONDictionary error:error];
}

@end
