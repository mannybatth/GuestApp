//
//  YKSStayInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSConstants.h"

typedef struct {
    
    NSUInteger numberOfDays;
    NSUInteger numberOfHours;
    NSUInteger numberOfMinutes;
    
} YKSTimeRemaining;

typedef NS_ENUM(NSUInteger, YKSStayStatus) {
    kYKSStayStatusUnknown,
    kYKSStayStatusNotYetStarted,
    kYKSStayStatusCurrent,
    kYKSStayStatusExpired,
};

@class YKSAddressInfo, YKSUserInfo;

@interface YKSStayInfo : NSObject

@property (nonatomic, strong, readonly) NSNumber * stayId;
@property (nonatomic, strong, readonly) NSNumber * userId;
@property (nonatomic, strong, readonly) NSString * hotelName;
@property (nonatomic, strong, readonly) NSString * hotelPhoneNumber;
@property (nonatomic, strong, readonly) YKSAddressInfo * hotelAddress;
@property (nonatomic, strong, readonly) NSString * roomNumber;
@property (nonatomic, strong, readonly) NSString * reservationNumber;
@property (nonatomic, strong, readonly) NSDate * arrivalDate;
@property (nonatomic, strong, readonly) NSString * checkInTime;
@property (nonatomic, strong, readonly) NSDate * departDate;
@property (nonatomic, strong, readonly) NSString * checkOutTime;
@property (nonatomic, strong) NSTimeZone * hotelTimezone;

@property (nonatomic, strong, readonly) NSArray * amenities;
@property (nonatomic, strong, readonly) YKSUserInfo * primaryGuest;
@property (nonatomic, readonly) NSInteger numberOfNights;
@property (nonatomic, readonly) NSInteger numberOfNightsLeft;
@property (nonatomic, readonly) YKSConnectionStatus connectionStatus;
@property (nonatomic, strong, readonly) NSNumber * maxStaySharesAllowed;

@property (nonatomic, strong) NSString * dashboardImageURL1x;
@property (nonatomic, strong) NSString * dashboardImageURL2x;
@property (nonatomic, strong) NSString * dashboardImageURL3x;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;
+ (NSArray *)newStaysWithJSONArray:(NSArray *)array;

- (YKSStayStatus)stayStatus;
- (YKSTimeRemaining)timeUntilStayBegins:(NSDate *)now;

@end
