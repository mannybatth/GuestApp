//
//  YKSAmenityInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAmenityInfo.h"
#import "YKSDateHelper.h"

@interface YKSAmenityInfo()

@property (nonatomic, strong) NSNumber * amenityId;
@property (nonatomic, strong, readwrite) NSString * name;
@property (nonatomic, strong, readwrite) NSString * openTime;
@property (nonatomic, strong, readwrite) NSString * closeTime;
@property (nonatomic, strong, readwrite) NSString * displayCategory;

//@property (nonatomic) YKSConnectionStatus connectionStatus;

#define ACCESSDOOR_MODEL_TEST 0

@end

@implementation YKSAmenityInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSAmenityInfo alloc] initWithJSONDictionary:dictionary];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.amenityId = NILIFNULL(dictionary[@"id"]);
    self.name = NILIFNULL(dictionary[@"name"]);
    self.openTime = NILIFNULL(dictionary[@"open_time"]);
    self.closeTime = NILIFNULL(dictionary[@"close_time"]);
    self.displayCategory = NILIFNULL(dictionary[@"door_display_category"]);
 
    //Since door category is split across both door_type + door_display_category
    //we need to check both in order to determine the doorCategory
    NSString * doorType = NILIFNULL(dictionary[@"door_type"]);
    
    if (self.displayCategory) {
       
        if ([self.displayCategory isEqualToString:@"amenity"]) {
            _doorCategory = kYKSDoorCategoryAmenity;
        } else if ([self.displayCategory isEqualToString:@"access"]) {
            _doorCategory = kYKSDoorCategoryAccess;
        }
        
    }
    
    if (doorType) {
        if ([doorType isEqualToString:@"E"]) {
            _doorCategory = kYKSDoorCategoryElevator;
        }
    }
    
    if (dictionary[@"connection_status"] == nil) {
        self.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
    } else {
        NSUInteger statusInt = [dictionary[@"connection_status"] integerValue];
        self.connectionStatus = (YKSConnectionStatus)statusInt;
    }
    
#if ACCESSDOOR_MODEL_TEST
    if ([self.name isEqualToString:@"Pool"] ||
        [self.name isEqualToString:@"Elevator"] ||
        [self.name isEqualToString:@"External Stairs"]) {
        self.subType = @"access";
    }
#endif
    
    if (self.name == nil || self.amenityId == nil) {
        NSLog(@"Cannot create the amenity - either no name or no amenityId:\nname: %@\namenityId: %@", self.name ? self.name : @"No Name", self.amenityId ? self.amenityId : @"No Id");
        return nil;
    }
    
    return self;
}


- (BOOL)isOpenNow {
    
    NSDate * now = [NSDate date];
    
    NSDate * openTime = [[YKSDateHelper sharedInstance] setDate:now withTimeString:self.openTime andTimeZone:nil];
    NSDate * closeTime = [[YKSDateHelper sharedInstance] setDate:now withTimeString:self.closeTime andTimeZone:nil];
    
    if (!openTime || !closeTime) {
        return YES; //err on the side of attempting to connect
    }
    
    // Handle case where open time and close time are the same
    if ([openTime isEqualToDate:closeTime]) {
        return YES;
    }
    
    if ([YKSDateHelper isDate:now betweenDate:openTime andDate:closeTime]) {
        return YES;
    } else {
        return NO;
    }
    
}


- (BOOL)isAlwaysOpen {
    
    if ([self.openTime isEqualToString:@"00:00"] && [self.closeTime isEqualToString:@"00:00"]) {
        return YES;
    } else if ([self.openTime isEqualToString:@"00:00"] && [self.closeTime isEqualToString:@"23:59"]) {
        return YES;
    } else if ([self.openTime isEqualToString:@""] && [self.closeTime isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}



- (NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@\nOpen Time: %@\nClose Time: %@",
            self.name ? self.name : @"", self.openTime, self.closeTime];
}

- (BOOL)isAccessDoorOrElevator {
  
    if (self.doorCategory == kYKSDoorCategoryAccess ||
               self.doorCategory == kYKSDoorCategoryElevator) {
        return YES;
    } else {
        return NO;
    }
    
}

// TODO: Remove comparison with Amenity.name after release to PROD
- (BOOL)isEqual:(id)object {
    
    if ([object isKindOfClass:[YKSAmenityInfo class]]) {
        
        YKSAmenityInfo *amenity = (YKSAmenityInfo *)object;
        if (self.amenityId) {
            if ([self.amenityId isEqualToNumber:amenity.amenityId]) {
                return YES;
            }
        } else {
            if ([self.name isEqualToString:amenity.name]) {
                return YES;
            }
        }
        
    }
//    else if ([object isKindOfClass:[YKSAmenity class]]) {
//        
//        YKSAmenity *amenity = (YKSAmenity *)object;
//        if (self.amenityId) {
//            if ([self.amenityId isEqualToNumber:amenity.amenityId]) {
//                return YES;
//            }
//        } else {
//            if ([self.name isEqualToString:amenity.name]) {
//                return YES;
//            }
//        }
//        
//    }
    
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
