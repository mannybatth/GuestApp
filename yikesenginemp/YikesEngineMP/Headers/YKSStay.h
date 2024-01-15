//
//  YKSStay.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"
@import YikesSharedModel;
//@import YikesSharedModel;

@class YKSUser, YKSHotel, YKSAmenity;

@interface YKSStay : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDate * arrivalDate;
@property (nonatomic, strong) NSString * checkInTime;
@property (nonatomic, strong) NSString * checkOutTime;
@property (nonatomic, strong) NSDate * createdOn;
@property (nonatomic, strong) NSDate * departDate;
@property (nonatomic, strong) NSNumber * hotelEquipmentId;
@property (nonatomic, strong) NSNumber * hotelId;
@property (nonatomic, strong) NSNumber * stayId;
@property (nonatomic, strong) NSNumber * isActive;
@property (nonatomic, strong) NSNumber * isAtHotel;
@property (nonatomic, strong) NSNumber * isCancelled;
@property (nonatomic, strong) NSNumber * isDeparted;
@property (nonatomic, strong) NSDate * modifiedOn;
@property (nonatomic, strong) NSString * reservationNumber;
@property (nonatomic, strong) NSString * roomNumber;
@property (nonatomic, strong) NSString * roomType;
@property (nonatomic, strong) NSString * stayComment;
@property (nonatomic, strong) NSNumber * userId;
@property (nonatomic, strong) NSArray * primaryYMen;
@property (nonatomic, strong) NSArray * amenities;
@property (nonatomic, assign) YKSConnectionStatus connectionStatus;

@property (nonatomic) NSUInteger numberOfNights;
@property (nonatomic) NSUInteger numberOfNightsLeft;

@property (nonatomic, strong) YKSHotel * hotel;
@property (nonatomic, strong) YKSUser * primaryGuest;

- (BOOL)isCurrent;

- (BOOL)areAnyAmenitiesOpen;

/**
 *  Parse JSON array into list of Stay objects.
 */
+ (NSArray *)newStaysFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single Stay object.
 */
+ (YKSStay *)newStayFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

- (YKSStayInfo *)newStayInfo;

/**
 *  Convenience method to return a set of binary (NSData instead of NSString) MAC addresses.
 */
//- (NSSet *)primaryYMenMACAddresses;

+ (YKSStay *)findStayById:(NSNumber *)stayId fromStays:(NSArray *)stays;
+ (YKSAmenity *)findAmenityById:(NSNumber *)amenityId fromStays:(NSArray *)stays;
+ (YKSAmenity *)findAmenityByName:(NSString *)name fromStays:(NSArray *)stays;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end
