//
//  YKSStayInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSStayInfo.h"
#import "YKSUserInfo.h"
#import "YKSAddressInfo.h"
#import "YKSAmenityInfo.h"
#import "YKSDateHelper.h"
//#import "YKSStay.h"

@interface YKSStayInfo ()

@property (nonatomic, strong) NSNumber * stayId;
@property (nonatomic, strong) NSNumber * userId;
@property (nonatomic, strong) NSString * hotelName;
@property (nonatomic, strong) NSString * hotelPhoneNumber;
@property (nonatomic, strong) YKSAddressInfo * hotelAddress;
@property (nonatomic, strong) NSString * roomNumber;
@property (nonatomic, strong) NSString * reservationNumber;
@property (nonatomic, strong) NSDate * arrivalDate;
@property (nonatomic, strong) NSString * checkInTime;
@property (nonatomic, strong) NSDate * departDate;
@property (nonatomic, strong) NSString * checkOutTime;
@property (nonatomic, strong) NSArray * amenities;

@property (nonatomic, strong) YKSUserInfo * primaryGuest;
@property (nonatomic) NSInteger numberOfNights;
@property (nonatomic) YKSConnectionStatus connectionStatus;
@property (nonatomic, strong) NSNumber * maxStaySharesAllowed;

@end

@implementation YKSStayInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSStayInfo alloc] initWithJSONDictionary:dictionary];
}

+ (NSArray *)newStaysWithJSONArray:(NSArray *)array
{
    NSMutableArray *listOfStayInfos = [NSMutableArray new];
    [array enumerateObjectsUsingBlock:^(NSDictionary *stayJSON, NSUInteger idx, BOOL *stop) {
        
        YKSStayInfo *stayInfo = [YKSStayInfo newWithJSONDictionary:stayJSON];
        [listOfStayInfos addObject:stayInfo];
        
    }];
    return listOfStayInfos;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    // NOTE: This should of been used earlier. All dates returned from the engine should be in GMT
    //[dateFormat setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    self.stayId = NILIFNULL(dictionary[@"id"]);
    self.userId = NILIFNULL(dictionary[@"user_id"]);
    self.hotelName = NILIFNULL(dictionary[@"hotel"][@"name"]);
    self.hotelPhoneNumber = NILIFNULL(dictionary[@"hotel"][@"contact_phone"]);
    self.hotelAddress = [YKSAddressInfo newWithJSONDictionary:dictionary[@"hotel"][@"address"]];
    self.roomNumber = NILIFNULL(dictionary[@"room_number"]);
    self.reservationNumber = NILIFNULL(dictionary[@"reservation_number"]);
    self.arrivalDate = [dateFormat dateFromString:dictionary[@"arrival_date"]];
    self.checkInTime = NILIFNULL(dictionary[@"check_in_time"]);
    self.departDate = [dateFormat dateFromString:dictionary[@"depart_date"]];
    self.checkOutTime = NILIFNULL(dictionary[@"check_out_time"]);
    self.numberOfNights = [dictionary[@"number_of_nights"] integerValue];
    self.maxStaySharesAllowed = NILIFNULL(dictionary[@"hotel"][@"max_secondary_guests"]);
   
    NSString * timeZone = NILIFNULL(dictionary[@"hotel"][@"local_tz"]);
   
    if (timeZone) {
        self.hotelTimezone = [[NSTimeZone alloc] initWithName:timeZone];
    }
    
    if ([dictionary[@"primary_guest"] isKindOfClass:[NSDictionary class]]) {
        self.primaryGuest = [YKSUserInfo newWithJSONDictionary:dictionary[@"primary_guest"]];
    }

    self.dashboardImageURL1x = NILIFNULL(dictionary[@"hotel"][@"assets"][@"dashboard_images"][@"1x"]);
    self.dashboardImageURL2x = NILIFNULL(dictionary[@"hotel"][@"assets"][@"dashboard_images"][@"2x"]);
    self.dashboardImageURL3x = NILIFNULL(dictionary[@"hotel"][@"assets"][@"dashboard_images"][@"3x"]);
    
    if (dictionary[@"connection_status"] == nil) {
        self.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
    } else {
        NSUInteger statusInt = [dictionary[@"connection_status"] integerValue];
        self.connectionStatus = (YKSConnectionStatus)statusInt;
    }
    
    if ([dictionary[@"amenities"] isKindOfClass:[NSArray class]]) {
        NSMutableArray *amenities = [[NSMutableArray alloc] init];
        for (NSDictionary *amenityDict in dictionary[@"amenities"]) {
            YKSAmenityInfo *amenityInfo = [YKSAmenityInfo newWithJSONDictionary:amenityDict];
            if (amenityInfo != nil) {
                [amenities addObject:amenityInfo];
            }
            else {
                NSLog(@"amenityInfo is nil from dictionary: %@", amenityDict);
            }
        }
        self.amenities = [NSArray arrayWithArray:amenities];
    }
    
    return self;
}

- (NSInteger)numberOfNightsLeft {
    return [YKSDateHelper nightsRemainingFromNow:[NSDate date] toDepartDate:self.departDate withArrivalDate:self.arrivalDate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Hotel: %@, Phone: %@, Address: %@, roomNumber: %@, reservationNumber: %@, check-in: %@ %@, check-out: %@ %@, numberOfNights: %lu, amenities: %@",
            self.hotelName,
            self.hotelPhoneNumber,
            self.hotelAddress,
            self.roomNumber,
            self.reservationNumber,
            self.arrivalDate,
            self.checkInTime,
            self.departDate,
            self.checkOutTime,
            (unsigned long)self.numberOfNights,
            self.amenities];
}


- (YKSStayStatus)stayStatus {
   
    NSDate * now = [NSDate date];
    
    NSDate * arrivalDateWithTime = [[YKSDateHelper sharedInstance] setDate:self.arrivalDate withTimeString:self.checkInTime andTimeZone:self.hotelTimezone];
   
    NSDate * departDateWithTime = [[YKSDateHelper sharedInstance] setDate:self.departDate withTimeString:self.checkOutTime andTimeZone:self.hotelTimezone];
 
    if (!arrivalDateWithTime || !departDateWithTime) {
        return kYKSStayStatusUnknown;
    }
    
    if ([YKSDateHelper isDate:now betweenDate:arrivalDateWithTime andDate:departDateWithTime]) {
        return kYKSStayStatusCurrent;
    }
    
    NSTimeInterval secondsRemaining = [departDateWithTime timeIntervalSinceDate:now];
    
    if (secondsRemaining > 0) {
        return kYKSStayStatusNotYetStarted;
    } else  {
        return kYKSStayStatusExpired; //since it's not current or before, this is the only other option
    }
}

- (YKSTimeRemaining)timeUntilStayBegins:(NSDate *)now {
   
    YKSTimeRemaining remaining;
    remaining.numberOfDays = 0;
    remaining.numberOfHours = 0;
    remaining.numberOfMinutes = 0;
   
    NSDate * arrivalDateWithTime = [[YKSDateHelper sharedInstance] setDate:self.arrivalDate withTimeString:self.checkInTime andTimeZone:self.hotelTimezone];
    
    NSTimeInterval secondsRemaining = [arrivalDateWithTime timeIntervalSinceDate:now];
    
    if (secondsRemaining <= 0) {
        
        return remaining;
        
    }
    
    //Since we are not showing seconds, add a minute to force anything less than a minute to show as "1 min"
    //secondsRemaining += 60;
  
    remaining.numberOfMinutes = (int)((secondsRemaining / 60)) % 60;
    remaining.numberOfHours = secondsRemaining / (60*60);
    remaining.numberOfDays = secondsRemaining / (60*60*24);
    
    return remaining;
}

- (BOOL)isEqual:(id)object {
    
    if ([object isKindOfClass:[YKSStayInfo class]]) {
        
        YKSStayInfo *stay = (YKSStayInfo *)object;
        if ([self.stayId isEqualToNumber:stay.stayId]) {
            return YES;
        }
        
    }
//    else if ([object isKindOfClass:[YKSStay class]]) {
//        
//        YKSStay *stay = (YKSStay *)object;
//        if ([self.stayId isEqualToNumber:stay.stayId]) {
//            return YES;
//        }
//        
//    }
    
    return NO;
}

- (NSUInteger)hash
{
    return [self.stayId hash];
}

@end
