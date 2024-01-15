//
//  YKSUserInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSUserInfo.h"
#import "YKSStayInfo.h"
#import "YKSStayShareInfo.h"
#import "YKSUserInviteInfo.h"
#import "YKSContactInfo.h"

@implementation YKSUserInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSUserInfo alloc] initWithJSONDictionary:dictionary];
}

+ (NSArray *)newUsersWithJSONArray:(NSArray *)array
{
    NSMutableArray *listOfUserInfos = [NSMutableArray new];
    [array enumerateObjectsUsingBlock:^(NSDictionary *userJSON, NSUInteger idx, BOOL *stop) {
        
        YKSUserInfo *userInfo = [YKSUserInfo newWithJSONDictionary:userJSON];
        [listOfUserInfos addObject:userInfo];
        
    }];
    return listOfUserInfos;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _userId = NILIFNULL(dictionary[@"id"]);
    _email = NILIFNULL(dictionary[@"email"]);
    _firstName = NILIFNULL(dictionary[@"first_name"]);
    _lastName = NILIFNULL(dictionary[@"last_name"]);
    _phone = NILIFNULL(dictionary[@"phone_number"]);
    _deviceId = NILIFNULL(dictionary[@"device_id"]);
    
    if ([dictionary[@"has_temp_password"] boolValue]) {
        _hasTempPassword = YES;
    }
    
    if ([dictionary[@"stays"] isKindOfClass:[NSArray class]]) {
        _stays = [YKSStayInfo newStaysWithJSONArray:dictionary[@"stays"]];
    }
    
    if ([dictionary[@"stay_shares"] isKindOfClass:[NSArray class]]) {
        _stayShares = [YKSStayShareInfo newStaySharesWithJSONArray:dictionary[@"stay_shares"]];
    }
    
    if ([dictionary[@"user_invites"] isKindOfClass:[NSArray class]]) {
        _userInvites = [YKSUserInviteInfo newUserInvitesWithJSONArray:dictionary[@"user_invites"]];
    }
    
    if ([dictionary[@"recent_contacts"] isKindOfClass:[NSArray class]]) {
        _recentContacts = [YKSContactInfo newContactsWithJSONArray:dictionary[@"recent_contacts"]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@ %@, Email: %@, Phone: %@, Stays: %@, Shares: %@, Invites: %@",
            self.firstName,
            self.lastName,
            self.email,
            self.phone,
            self.stays,
            self.stayShares,
            self.userInvites];
}

@end
