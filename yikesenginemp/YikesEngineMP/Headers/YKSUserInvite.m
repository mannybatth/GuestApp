//
//  YKSUserInvite.m
//  yEngine
//
//  Created by Manny Singh on 9/16/15.
//
//

#import "YKSUserInvite.h"

@import YikesSharedModel;

@implementation YKSUserInvite

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"inviteId": @"id",
             @"firstName": @"first_name",
             @"lastName": @"last_name",
             @"email": @"email",
             @"phoneNumber": @"phone_number",
             @"acceptedOn": @"accepted_on",
             @"declinedOn": @"declined_on",
             @"createdOn": @"created_on",
             @"inviteeUserId": @"invitee_user_id",
             @"inviterUserId": @"inviter_user_id",
             @"relatedStayId": @"related_stay_id"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSValueTransformer *)acceptedOnJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] dateFromString:dateString];
    } reverseBlock:^id(NSDate *date, BOOL *success, NSError *__autoreleasing *error) {
        return [[[YKSDateHelper sharedInstance] simpleDateFormatterWithTime] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)declinedOnJSONTransformer {
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

+ (NSArray *)newUserInvitesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSUserInvite.class fromJSONArray:JSONArray error:error];
}

+ (YKSUserInvite *)newUserInviteFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSUserInvite.class fromJSONDictionary:JSONDictionary error:error];
}

@end
