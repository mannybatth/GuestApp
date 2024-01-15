//
//  YKSPhone.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@class YKSUser;

@interface YKSPhone : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDate * createdOn;
@property (nonatomic, strong) NSString * currentLapAddress;
@property (nonatomic, strong) NSNumber * id;
@property (nonatomic, strong) NSDate * modifiedOn;
@property (nonatomic, strong) NSString * osVersion;
@property (nonatomic, strong) NSString * phoneDescription;
@property (nonatomic, strong) NSString * phoneNumber;
@property (nonatomic, strong) NSString * phoneStatus;
@property (nonatomic, strong) NSString * phoneTypeName;
@property (nonatomic, strong) NSNumber * primaryPhone;
@property (nonatomic, strong) NSData * privateKey;

@property (nonatomic, strong) YKSUser * user;

/**
 *  Parse JSON dictionary into single Phone object.
 */
+ (YKSPhone *)newPhoneFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
