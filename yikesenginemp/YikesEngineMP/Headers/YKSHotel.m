//
//  YKSHotel.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSHotel.h"
#import "YKSWeather.h"
#import "YKSAddress.h"

@implementation YKSHotel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"checkInTime": @"check_in_time",
             @"checkOutTime": @"check_out_time",
             @"contactPhone": @"contact_phone",
             @"id": @"id",
             @"name": @"name",
             @"address": @"address",
             @"maxSecondaryGuests": @"max_secondary_guests",
             @"dashboardImageURL1x": @"assets.dashboard_images.1x",
             @"dashboardImageURL2x": @"assets.dashboard_images.2x",
             @"dashboardImageURL3x": @"assets.dashboard_images.3x",
             @"localTimezone":@"local_tz"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Remove all non-numeric characters
    self.contactPhone = [[self.contactPhone componentsSeparatedByCharactersInSet:
                          [[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                         componentsJoinedByString:@""];
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSValueTransformer *)addressJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSAddress.class];
}

+ (NSValueTransformer *)localTimezoneJSONTransformer {
    
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *timezoneString, BOOL *success, NSError *__autoreleasing *error) {
        
        NSTimeZone * timezone = [[NSTimeZone alloc] initWithName:timezoneString];
        return timezone;
        
    } reverseBlock:^id(NSTimeZone * timezone, BOOL *success, NSError *__autoreleasing *error) {
        
        return [timezone name];
        
    }];
    
}

+ (NSArray *)newHotelsFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSHotel.class fromJSONArray:JSONArray error:error];
}

+ (YKSHotel *)newHotelFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSHotel.class fromJSONDictionary:JSONDictionary error:error];
}

@end
