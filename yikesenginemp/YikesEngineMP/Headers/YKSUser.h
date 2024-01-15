//
//  YKSUser.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@import YikesSharedModel;

@class YKSStay;

@interface YKSUser : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSDate * firstApiLoginOn;
@property (nonatomic, strong) NSDate * createdOn;
@property (nonatomic, strong) NSString * deviceId;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSNumber * id;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * middleInitial;
@property (nonatomic, strong) NSString * phoneNumber;
@property (nonatomic, strong) NSNumber * primaryPhone;
@property (atomic, assign)    BOOL       hasTempPassword;
@property (atomic, assign)    BOOL       eulaAccepted;


@property (nonatomic, strong) NSArray * stays;
@property (nonatomic, strong) NSArray * stayShares;
@property (nonatomic, strong) NSArray * userInvites;
@property (nonatomic, strong) NSArray * recentContacts;

@property (nonatomic, strong, readonly) YKSStay * currentStay;

/**
 *  Parse JSON array into list of User objects.
 */
+ (NSArray *)newUsersFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single User object.
 */
+ (YKSUser *)newUserFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

- (YKSUserInfo *)newUserInfo;

@end
