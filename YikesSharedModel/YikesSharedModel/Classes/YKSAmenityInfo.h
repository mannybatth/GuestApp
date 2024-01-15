//
//  YKSAmenityInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 6/24/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSConstants.h"

typedef enum {
    
    kYKSDoorCategoryAmenity,
    kYKSDoorCategoryAccess,
    kYKSDoorCategoryElevator
    
} YKSDoorCategory;

@interface YKSAmenityInfo : NSObject

@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, strong, readonly) NSString * openTime;
@property (nonatomic, strong, readonly) NSString * closeTime;
@property (nonatomic, readonly) YKSDoorCategory doorCategory;
@property (nonatomic, assign) YKSConnectionStatus connectionStatus;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;

- (BOOL)isAccessDoorOrElevator;
- (BOOL)isOpenNow;
- (BOOL)isAlwaysOpen;


@end
