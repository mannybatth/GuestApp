//
//  YKSUserInviteInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 9/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSUserInviteInfo.h"
#import "YKSConstants.h"

@interface YKSUserInviteInfo()

@property (nonatomic, strong) NSNumber * inviteId;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSNumber * relatedStayId;
@property (nonatomic) BOOL isAccepted;
@property (nonatomic) BOOL isDeclined;

@end

@implementation YKSUserInviteInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSUserInviteInfo alloc] initWithJSONDictionary:dictionary];
}

+ (NSArray *)newUserInvitesWithJSONArray:(NSArray *)array
{
    NSMutableArray *listOfUserInviteInfos = [NSMutableArray new];
    [array enumerateObjectsUsingBlock:^(NSDictionary *userInviteJSON, NSUInteger idx, BOOL *stop) {
        
        YKSUserInviteInfo *userInviteInfo = [YKSUserInviteInfo newWithJSONDictionary:userInviteJSON];
        [listOfUserInviteInfos addObject:userInviteInfo];
        
    }];
    return listOfUserInviteInfos;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.inviteId = NILIFNULL(dictionary[@"id"]);
    self.firstName = NILIFNULL(dictionary[@"first_name"]);
    self.lastName = NILIFNULL(dictionary[@"last_name"]);
    self.email = NILIFNULL(dictionary[@"email"]);
    self.relatedStayId = NILIFNULL(dictionary[@"related_stay_id"]);
    
    if ([dictionary[@"accepted_on"] boolValue]) {
        self.isAccepted = YES;
        //TODO: compare with Develop and take last version
    } else if ([dictionary[@"declined_on"] boolValue]) {
        self.isDeclined = YES;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Email: %@, FirstName: %@, LastName: %@, Accepted: %@, Declined: %@, StayId: %@",
            self.email,
            self.firstName,
            self.lastName,
            @(self.isAccepted),
            @(self.isDeclined),
            self.relatedStayId];
}

@end
