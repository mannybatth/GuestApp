//
//  YKSUser.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSUser.h"
#import "YKSStay.h"
#import "YKSStayShare.h"
#import "YKSUserInvite.h"
#import "YKSContact.h"
#import "YKSInternalConstants.h"

@implementation YKSUser

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"firstApiLoginOn": @"first_api_login_on",
             @"createdOn": @"created_on",
             @"deviceId": @"device_id",
             @"email": @"email",
             @"firstName": @"first_name",
             @"id": @"id",
             @"lastName": @"last_name",
             @"middleInitial": @"middle_initial",
             @"phoneNumber": @"phone_number",
             @"primaryPhone": @"primary_phone",
             @"hasTempPassword": @"has_temp_password",
             @"stays": @"stays",
             @"stayShares": @"stay_shares",
             @"userInvites": @"user_invites",
             @"recentContacts": @"recent_contacts"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSValueTransformer *)staysJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSStay.class];
}

+ (NSValueTransformer *)staySharesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSStayShare.class];
}

+ (NSValueTransformer *)userInvitesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSUserInvite.class];
}

+ (NSValueTransformer *)recentContactsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:YKSContact.class];
}

+ (NSValueTransformer *)firstApiLoginOnJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)createdOnJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] stringFromDate:date];
    }];
}

+ (NSArray *)newUsersFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSUser.class fromJSONArray:JSONArray error:error];
}

+ (YKSUser *)newUserFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    if (NILIFNULL(JSONDictionary[@"has_temp_password"]) == nil) {
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:JSONDictionary];
        newDict[@"has_temp_password"] = false;
        JSONDictionary = newDict;
    }
    return [MTLJSONAdapter modelOfClass:YKSUser.class fromJSONDictionary:JSONDictionary error:error];
}

- (YKSUserInfo *)newUserInfo
{
    NSError *error = nil;
    NSDictionary *userJSON = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (!error) {
        YKSUserInfo *userInfo = [YKSUserInfo newWithJSONDictionary:userJSON];
        return userInfo;
    }
    return nil;
}

- (YKSStay *)currentStay
{
    if (self.stays && self.stays.count > 0) {
        return [self.stays firstObject];
    }
    return nil;
}

@end
