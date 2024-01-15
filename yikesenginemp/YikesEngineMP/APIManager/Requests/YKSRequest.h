//
//  YKSRequest.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Base Request class
 */

#import "YKSHTTPClient.h"

@interface YKSRequest : NSObject


/**
 *  API Endpoints
 */
+ (NSString *)apiURLForLogin;
+ (NSString *)apiURLForLogout;
+ (NSString *)apiURLForUsers;
+ (NSString *)apiURLForUserWithId:(NSNumber *)userId;
+ (NSString *)apiURLForUserAndStaysWithUserId:(NSNumber *)userId;
+ (NSString *)apiURLForUserAndCurrentStaysForDate:(NSString *)date userId:(NSNumber *)userId;
+ (NSString *)apiURLForHotelWithId:(NSNumber *)hotelId;
+ (NSString *)apiURLForVerifyWithEmail:(NSString *)email;
+ (NSString *)apiURlForPasswordResetWithEmail:(NSString *)email;
+ (NSString *)apiURLForStaySharesForUserId:(NSNumber *)userId;
+ (NSString *)apiURLForStaySharesForStayId:(NSNumber *)stayId;
+ (NSString *)apiURlForStayShareWithId:(NSNumber *)stayShareId stayId:(NSNumber *)stayId;
+ (NSString *)apiURLForUserInvitesWithUserId:(NSNumber *)userId;
+ (NSString *)apiURLForUserInviteWithId:(NSNumber *)inviteId userId:(NSNumber *)userId;
+ (NSString *)apiURLForContactsForUserId:(NSNumber *)userId;
+ (NSString *)apiURLForContactsWithId:(NSNumber *)contactId userId:(NSNumber *)userId;
+ (NSString *)apiURLForUpdatePasswordWith:(NSNumber *)userId;
@end
