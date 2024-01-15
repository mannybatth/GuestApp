//
//  YKSAmenity.m
//  YikesEnginePod
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

#import "YKSAmenity.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

@implementation YKSAmenity

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"amenityId": @"id",
             @"name": @"name",
             @"openTime": @"open_time",
             @"closeTime": @"close_time",
             @"connectionStatus": @"connection_status",
             @"doorType": @"door_type",
             @"displayCategory":@"door_display_category",
             @"primaryYManMACAddress":@"primary_yman"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSArray *)newAmenitiesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSAmenity.class fromJSONArray:JSONArray error:error];
}

+ (YKSAmenity *)newAmenityFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSAmenity.class fromJSONDictionary:JSONDictionary error:error];
}

- (YKSAmenityInfo *)newAmenityInfo
{
    NSError *error = nil;
    NSDictionary *amenityJSON = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (!error) {
        YKSAmenityInfo *amenityInfo = [YKSAmenityInfo newWithJSONDictionary:amenityJSON];
        return amenityInfo;
    }
    return nil;
}


- (BOOL)isOpenNow {

    NSDate * now = [NSDate date];
    
    
    NSDate * openTime = [[YKSDateHelper sharedInstance] setDate:now withTimeString:self.openTime andTimeZone:self.hotelTimezone];
    NSDate * closeTime = [[YKSDateHelper sharedInstance] setDate:now withTimeString:self.closeTime andTimeZone:self.hotelTimezone];
   
    if (!openTime || !closeTime) {
        return YES; //err on the side of attempting to connect
    }
    
    if ([YKSDateHelper isDate:now betweenDate:openTime andDate:closeTime]) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL)isElevator {
    
    return [self.doorType isEqualToString:@"E"];
    
}

- (NSData *)binaryMacAddress {
    
    return [YKSBinaryHelper binaryFromHexString:self.primaryYManMACAddress];
    
}

// TODO: Remove comparison with Amenity.name after release to PROD
- (BOOL)isEqual:(id)object {
    
    if (![object isKindOfClass:[YKSAmenity class]]) {
        return NO;
    }
    
    YKSAmenity *amenity = (YKSAmenity *)object;
    
    if (self.amenityId) {
        
        if ([self.amenityId isEqualToNumber:amenity.amenityId]) {
            return YES;
        }
        
    } else {
        
        if ([self.name isEqualToString:amenity.name]) {
            return YES;
        }
    }
    
    return NO;
}

// TODO: Remove hash for Amenity.name after release to PROD
- (NSUInteger)hash
{
    if (self.amenityId) {
        return [self.amenityId hash];
    }
    return [self.name hash];
}

@end
