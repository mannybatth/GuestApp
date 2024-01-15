//
//  YKSHotel.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@class YKSWeather, YKSAddress;

@interface YKSHotel : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString * checkInTime;
@property (nonatomic, strong) NSString * checkOutTime;
@property (nonatomic, strong) NSString * contactPhone;
@property (nonatomic, strong) NSNumber * id;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSNumber * maxSecondaryGuests;

@property (nonatomic, strong) YKSAddress * address;
@property (nonatomic, strong) NSArray * stays;
@property (nonatomic, strong) YKSWeather * weather;

@property (nonatomic, strong) NSTimeZone * localTimezone;

@property (nonatomic, strong) NSString * dashboardImageURL1x;
@property (nonatomic, strong) NSString * dashboardImageURL2x;
@property (nonatomic, strong) NSString * dashboardImageURL3x;

/**
 *  Parse JSON array into list of Hotel objects.
 */
+ (NSArray *)newHotelsFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single Hotel object.
 */
+ (YKSHotel *)newHotelFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
