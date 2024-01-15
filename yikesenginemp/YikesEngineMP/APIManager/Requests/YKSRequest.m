//
//  YKSRequest.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSRequest.h"

@implementation YKSRequest

+ (NSString *)apiURLForLogin
{
    return @"/ycentral/api/session/login";
}

+ (NSString *)apiURLForLogout
{
    return @"/ycentral/api/session/logout";
}

+ (NSString *)apiURLForUsers
{
    return @"/ycentral/api/users";
}

+ (NSString *)apiURLForUpdatePasswordWith:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/password_change", (long)userId.integerValue];
}


+ (NSString *)apiURLForUserWithId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li", (long)userId.integerValue];
}

+ (NSString *)apiURLForUserAndStaysWithUserId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/stays?_expand=user,hotel&is_active=true", (long)userId.integerValue];
}

+ (NSString *)apiURLForUserAndCurrentStaysForDate:(NSString *)date userId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/stays?_expand=user,hotel&is_active=true&current_for=%@", (long)userId.integerValue, date];
}

+ (NSString *)apiURLForHotelWithId:(NSNumber *)hotelId
{
    return [NSString stringWithFormat:@"/ycentral/api/hotels/%li", (long)hotelId.integerValue];
}

+ (NSString *)apiURLForVerifyWithEmail:(NSString *)email
{
    return [NSString stringWithFormat:@"/ycentral/api/verify?email=%@", email];
}

+ (NSString *)apiURlForPasswordResetWithEmail:(NSString *)email
{
    return [NSString stringWithFormat:@"/ycentral/api/users/password_resets?email=%@", email];
}

+ (NSString *)apiURLForStaySharesForUserId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/stay_shares", (long)userId.integerValue];
}

+ (NSString *)apiURLForStaySharesForStayId:(NSNumber *)stayId
{
    return [NSString stringWithFormat:@"/ycentral/api/stays/%li/shares", (long)stayId.integerValue];
}

+ (NSString *)apiURlForStayShareWithId:(NSNumber *)stayShareId stayId:(NSNumber *)stayId
{
    return [NSString stringWithFormat:@"/ycentral/api/stays/%li/shares/%li", (long)stayId.integerValue, (long)stayShareId.integerValue];
}

+ (NSString *)apiURLForUserInvitesWithUserId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/invites", (long)userId.integerValue];
}

+ (NSString *)apiURLForUserInviteWithId:(NSNumber *)inviteId userId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/invites/%li", (long)userId.integerValue, (long)inviteId.integerValue];
}

+ (NSString *)apiURLForContactsForUserId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/contacts", (long)userId.integerValue];
}

+ (NSString *)apiURLForContactsWithId:(NSNumber *)contactId userId:(NSNumber *)userId
{
    return [NSString stringWithFormat:@"/ycentral/api/users/%li/contacts/%li", (long)userId.integerValue, (long)contactId.integerValue];
}

@end
