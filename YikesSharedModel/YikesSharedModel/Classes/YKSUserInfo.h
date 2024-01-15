//
//  YKSUserInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSUserInfo : NSObject

@property (nonatomic, strong, readonly, nonnull) NSNumber * userId;
@property (nonatomic, strong, readonly, nonnull) NSString * email;
@property (nonatomic, strong, readonly, nonnull) NSString * firstName;
@property (nonatomic, strong, readonly, nonnull) NSString * lastName;
@property (nonatomic, strong, readonly, nullable) NSString * phone;
@property (nonatomic, strong, readonly, nonnull) NSString * deviceId;
@property (atomic, assign, readonly)    BOOL       hasTempPassword;

@property (nonatomic, strong, readonly, nonnull) NSArray * stays;

@property (nonatomic, strong, readonly, nonnull) NSArray * stayShares;
@property (nonatomic, strong, readonly, nonnull) NSArray * userInvites;
@property (nonatomic, strong, readonly, nonnull) NSArray * recentContacts;

+ (instancetype _Nullable)newWithJSONDictionary:(NSDictionary * _Nonnull)dictionary;
+ (NSArray * _Nonnull)newUsersWithJSONArray:(NSArray * _Nonnull)array;

@end
