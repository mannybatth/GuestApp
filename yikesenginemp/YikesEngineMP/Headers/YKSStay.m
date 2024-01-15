//
//  YKSStay.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSStay.h"
#import "YKSHotel.h"
#import "YKSUser.h"
#import "YKSPrimaryYMan.h"
#import "YKSAmenity.h"
#import "YMan.h"

@import YikesSharedModel;

@implementation YKSStay

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"arrivalDate": @"arrival_date",
             @"checkInTime": @"check_in_time",
             @"checkOutTime": @"check_out_time",
             @"createdOn": @"created_on",
             @"departDate": @"depart_date",
             @"hotelEquipmentId": @"hotel_equipment_id",
             @"hotelId": @"hotel_id",
             @"stayId": @"id",
             @"isActive": @"is_active",
             @"isAtHotel": @"is_at_hotel",
             @"isCancelled": @"is_cancelled",
             @"isDeparted": @"is_departed",
             @"modifiedOn": @"modified_on",
             @"reservationNumber": @"reservation_number",
             @"roomNumber": @"room_number",
             @"roomType": @"room_type",
             @"stayComment": @"stay_comment",
             @"userId": @"user_id",
             @"primaryYMen": @"primary_ymen",
             @"hotel": @"hotel",
             @"amenities": @"amenities",
             @"numberOfNights": @"number_of_nights",
             @"connectionStatus": @"connection_status",
             @"primaryGuest": @"primary_guest"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    if ([self.arrivalDate isKindOfClass:[NSDate class]]) {
        self.numberOfNights = [YKSDateHelper daysBetweenDate:self.arrivalDate andDate:self.departDate];
    }
    
    //Add the elevator
    [self addElevatorToAmenities];
  
    //
    [self setHotelTimeZoneOnAmenities];
   
    //TO be done when we move primary ymen completely to stay object
    /*
    NSMutableArray *yMen = [NSMutableArray array];
    [self.primaryYMen enumerateObjectsUsingBlock:^(YKSPrimaryYMan *primaryYMan, NSUInteger idx, BOOL *stop) {
        YMan *yMan = [[YMan alloc] initWithAddress:[YKSBinaryHelper binaryFromHexString:primaryYMan.macAddress]];
        [yMen addObject:yMan];
    }];
    self.yMen = [NSArray arrayWithArray:yMen];
    */
    
    return self;
}

+ (NSValueTransformer *)primaryYMenJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSPrimaryYMan.class];
}

+ (NSValueTransformer *)hotelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSHotel.class];
}

+ (NSValueTransformer *)primaryGuestJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSUser.class];
}

+ (NSValueTransformer *)amenitiesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSAmenity.class];
}

+ (NSValueTransformer *)arrivalDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatter] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatter] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)departDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatter] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatter] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)createdOnJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)modifiedOnJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] stringFromDate:date];
    }];
}

+ (NSArray *)newStaysFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSStay.class fromJSONArray:JSONArray error:error];
}

+ (YKSStay *)newStayFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSStay.class fromJSONDictionary:JSONDictionary error:error];
}

- (YKSStayInfo *)newStayInfo
{
    NSError *error = nil;
    NSDictionary *stayJSON = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (!error) {
        YKSStayInfo *stayInfo = [YKSStayInfo newWithJSONDictionary:stayJSON];
        return stayInfo;
    }
    return nil;
}

- (NSUInteger)numberOfNightsLeft {
    return [YKSDateHelper nightsRemainingFromNow:[NSDate date] toDepartDate:self.departDate withArrivalDate:self.arrivalDate];
}

+ (YKSStay *)findStayById:(NSNumber *)stayId fromStays:(NSArray *)stays {
    
    for (YKSStay *stay in stays) {
        if ([stay.stayId isEqualToNumber:stayId]) {
            return stay;
        }
    }
    return nil;
}

+ (YKSAmenity *)findAmenityById:(NSNumber *)amenityId fromStays:(NSArray *)stays
{
    for (YKSStay *stay in stays) {
        for (YKSAmenity *amenity  in stay.amenities) {
            if ([amenity.amenityId isEqualToNumber:amenityId]) {
                return amenity;
            }
        }
    }
    return nil;
}

+ (YKSAmenity *)findAmenityByName:(NSString *)name fromStays:(NSArray *)stays
{
    for (YKSStay *stay in stays) {
        for (YKSAmenity *amenity  in stay.amenities) {
            if ([amenity.name isEqualToString:name]) {
                return amenity;
            }
        }
    }
    return nil;
}

- (BOOL)isCurrent {
   
    return [self isCurrent:[NSDate date]];
    
}

- (BOOL)isCurrent:(NSDate *)now {
    
    NSDate *arrivalDate = [[YKSDateHelper sharedInstance] setDate:self.arrivalDate withTimeString:self.checkInTime andTimeZone:self.hotel.localTimezone];
    
    NSDate *departDate = [[YKSDateHelper sharedInstance] setDate:self.departDate withTimeString:self.checkOutTime andTimeZone:self.hotel.localTimezone];
    
    if (!arrivalDate || !departDate) {
        return NO;
    }
    
    if ([YKSDateHelper isDate:now betweenDate:arrivalDate andDate:departDate]) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL)areAnyAmenitiesOpen {

    for (YKSAmenity * amenity in self.amenities) {
       
        if ([amenity isOpenNow]) {
            return YES;
        }
        
    }
    return NO;
    
}

//Since each Amenity object doesn't know about its hotel, we need to set the timezone so it can use it for opening time calculations
- (void)setHotelTimeZoneOnAmenities {
   
    for (YKSAmenity * amenity in self.amenities) {
       
        amenity.hotelTimezone = self.hotel.localTimezone;
        
    }
    
}

#pragma mark Temporary method until yCentral implements elevator amenity doors

- (void)addElevatorToAmenities {
    
    for (YKSAmenity * amenity in self.amenities) {
        if ([amenity.name isEqualToString:@"Elevator"]) {
            return;
        }
    }
   
    NSDictionary * elevatorDict = @{
                                @"id": @1,
                                @"name": @"Elevator",
                                @"open_time": @"00:00",
                                @"close_time": @"00:00",
                                @"door_type": @"E"
                                };
    
   
    YKSAmenity * elevator = [MTLJSONAdapter modelOfClass:[YKSAmenity class] fromJSONDictionary:elevatorDict error:nil];
   
    NSMutableArray * toAdd = [self.amenities mutableCopy];
    [toAdd addObject:elevator];
    
    
    self.amenities = [NSArray arrayWithArray:toAdd];
    
}


- (BOOL)isEqual:(id)object {
    
    if (![object isKindOfClass:[YKSStay class]]) {
        return NO;
    }
    
    YKSStay *stay = (YKSStay *)object;
    
    if ([self.stayId isEqualToNumber:stay.stayId]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.stayId hash];
}


@end
