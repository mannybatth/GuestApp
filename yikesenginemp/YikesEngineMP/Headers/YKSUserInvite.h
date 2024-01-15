//
//  YKSUserInvite.h
//  yEngine
//
//  Created by Manny Singh on 9/16/15.
//
//

#import "YKSModel.h"

@interface YKSUserInvite : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSNumber * inviteId;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * phoneNumber;
@property (nonatomic, strong) NSDate * acceptedOn;
@property (nonatomic, strong) NSDate * declinedOn;
@property (nonatomic, strong) NSDate * createdOn;
@property (nonatomic, strong) NSNumber * inviteeUserId;
@property (nonatomic, strong) NSNumber * inviterUserId;
@property (nonatomic, strong) NSNumber * relatedStayId;

/**
 *  Parse JSON array into list of YKSUserInvite objects.
 */
+ (NSArray *)newUserInvitesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single YKSUserInvite object.
 */
+ (YKSUserInvite *)newUserInviteFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
