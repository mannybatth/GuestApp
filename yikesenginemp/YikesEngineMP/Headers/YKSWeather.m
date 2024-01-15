//
//  YKSWeather.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSWeather.h"
#import "YKSHotel.h"

@implementation YKSWeather

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"conditionIconId": @"condition_icon_id",
             @"conditionLabel": @"condition_label",
             @"currentTemp": @"current_temp",
             @"highTemp": @"high_temp",
             @"lowTemp": @"low_temp",
             @"modifiedOn": @"modified_on",
             @"unit": @"unit"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (YKSWeather *)newWeatherFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSWeather.class fromJSONDictionary:JSONDictionary error:error];
}

@end
