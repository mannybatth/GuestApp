//
//  YKSPhone.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSPhone.h"
#import "YKSUser.h"

@implementation YKSPhone

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"createdOn": @"created_on",
             @"currentLapAddress": @"current_lap_address",
             @"id": @"id",
             @"modifiedOn": @"modified_on",
             @"osVersion": @"os_version",
             @"phoneDescription": @"phone_description",
             @"phoneNumber": @"phone_number",
             @"phoneStatus": @"phone_status",
             @"phoneTypeName": @"phone_type_name",
             @"primaryPhone": @"primary_phone",
             @"privateKey": @"private_key"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (YKSPhone *)newPhoneFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSPhone.class fromJSONDictionary:JSONDictionary error:error];
}

@end
