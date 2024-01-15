//
//  YKSAddressInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 5/28/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSAddressInfo : NSObject

@property (nonatomic, strong, readonly) NSString * addressLine1;
@property (nonatomic, strong, readonly) NSString * addressLine2;
@property (nonatomic, strong, readonly) NSString * addressLine3;
@property (nonatomic, strong, readonly) NSString * city;
@property (nonatomic, strong, readonly) NSString * country;
@property (nonatomic, strong, readonly) NSString * postalCode;
@property (nonatomic, strong, readonly) NSString * stateCode;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;

@end
