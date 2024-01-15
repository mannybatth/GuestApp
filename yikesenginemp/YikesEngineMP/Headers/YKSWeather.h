//
//  YKSWeather.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@class YKSHotel;

@interface YKSWeather : YKSModel <MTLJSONSerializing>

//@property (nonatomic, strong) NSNumber * conditionCode;
@property (nonatomic, strong) NSString * conditionIconId;
@property (nonatomic, strong) NSString * conditionLabel;
//@property (nonatomic, strong) NSString * conditionLabelDetail;
@property (nonatomic, strong) NSNumber * currentTemp;
@property (nonatomic, strong) NSNumber * highTemp;
@property (nonatomic, strong) NSNumber * lowTemp;
@property (nonatomic, strong) NSDate * modifiedOn;
@property (nonatomic, strong) NSString * unit;

@property (nonatomic, strong) NSDate * receivedOn;
@property (nonatomic, strong) YKSHotel * hotel;

/**
 *  Parse JSON dictionary into single Weather object.
 */
+ (YKSWeather *)newWeatherFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
