//
//  YKSAddress.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@interface YKSAddress : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString * addressLine1;
@property (nonatomic, strong) NSString * addressLine2;
@property (nonatomic, strong) NSString * addressLine3;
@property (nonatomic, strong) NSString * city;
@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * postalCode;
@property (nonatomic, strong) NSString * stateCode;

/**
 *  Parse JSON dictionary into single Address object.
 */
+ (YKSAddress *)newAddressFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
