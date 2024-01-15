//
//  YKSAmenity.h
//  YikesEnginePod
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

#import "YKSModel.h"

@import YikesSharedModel;

@interface YKSAmenity : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSNumber * amenityId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * openTime;
@property (nonatomic, strong) NSString * closeTime;
@property (nonatomic, strong) NSString * doorType;
@property (nonatomic, strong) NSString * displayCategory;
@property (nonatomic, strong) NSString * primaryYManMACAddress;
@property (nonatomic, strong) NSTimeZone * hotelTimezone;
@property (nonatomic, assign) YKSConnectionStatus connectionStatus;

/**
 *  Parse JSON array into list of Amenity objects.
 */
+ (NSArray *)newAmenitiesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single Amenity object.
 */
+ (YKSAmenity *)newAmenityFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

- (YKSAmenityInfo *)newAmenityInfo;

- (BOOL)isOpenNow;

- (BOOL)isElevator;

- (NSData *)binaryMacAddress;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end
