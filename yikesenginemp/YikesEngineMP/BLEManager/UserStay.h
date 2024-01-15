//
//  Stay.h
//  yikes
//
//  Created by Roger on 8/19/14.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface UserStay : NSObject

@property (nonatomic, strong) NSNumber * is_active;
@property (nonatomic, strong) NSNumber * at_hotel_flag;
@property (nonatomic, strong) NSString * stay_status_code;

@property (nonatomic, strong) NSDate * arrival_date;
@property (nonatomic, strong) NSDate * depart_date;

@property (nonatomic, strong) NSString * reservation_number;

@property (nonatomic, strong) NSString * room_number;

@property (nonatomic, strong) NSSet * primary_ymen;

- (BOOL) isActive;
- (NSSet *)primary_ymen_mac_addresses;

@end
