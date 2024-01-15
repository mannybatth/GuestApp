//
//  YKSUserRequest.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSUserRequest.h"
#import "YKSUser.h"
#import "YKSStay.h"
#import "YKSStayShare.h"
#import "YKSUserInvite.h"
#import "YKSContact.h"

@implementation YKSUserRequest

/**
 *  What this method does:
 *  1. Calls /ycentral/api/users/XXX/stays?_expand=user,hotel&is_active=true&current_for=<date>
 *  2. Modifies returned user dictionary to include list of stays
 *  3. Creates new YKSUser from user dictionary, while also transforming stay, hotel, address, etc into objects
 *  4. Returns YKSUser
 */
+ (void)getUserAndStaysWithUserId:(NSNumber *)userId
                          success:(void (^)(YKSUser *, AFHTTPRequestOperation *))successBlock
                          failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *date = [NSDate date];
    
    NSString *url = [self apiURLForUserAndCurrentStaysForDate:[dateFormatter stringFromDate:date] userId:userId];
    
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSMutableDictionary *userJSON = [NSMutableDictionary dictionaryWithDictionary:responseObject[@"response_body"][@"user"]];
        
        if ([responseObject[@"response_body"][@"stay"] isKindOfClass:[NSArray class]]) {
            userJSON[@"stays"] = [NSMutableArray arrayWithArray:responseObject[@"response_body"][@"stay"]];
        }
        
        NSError *error = nil;
        YKSUser *user = [YKSUser newUserFromJSON:userJSON error:&error];
        if (!error) {
            successBlock(user, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)getStaySharesForUserId:(NSNumber *)userId
                       success:(void (^)(NSArray *, AFHTTPRequestOperation *))successBlock
                       failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForStaySharesForUserId:userId];
    
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *staySharesJSONArray = responseObject[@"response_body"][@"stay_shares"];
        
        NSError *error = nil;
        NSArray *stayShares = [YKSStayShare newStaySharesFromJSON:staySharesJSONArray error:&error];
        
        if (!error) {
            successBlock(stayShares, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

// TODO: Create StayShare object from response
+ (void)createStayShareForStayId:(NSNumber *)stayId
                          userId:(NSNumber *)userId
                         success:(void (^)(YKSStayShare *, AFHTTPRequestOperation *))successBlock
                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForStaySharesForStayId:stayId];
    
    NSDictionary *params = @{
                             @"user_id":userId
                             };
    
    [[YKSHTTPClient operationManager] POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *stayShareLocation = operation.response.allHeaderFields[@"Location"];
        
        if (stayShareLocation && stayShareLocation.length > 0) {
            
            NSURL *url = [NSURL URLWithString:stayShareLocation];
            NSString *stayShareId = [url.path lastPathComponent];
            
            NSDictionary *dict = @{
                                   @"id": @([stayShareId integerValue]),
                                   @"stay_id": stayId,
                                   @"user_id": userId,
                                   @"status": @"pending"
                                   };
            
            YKSStayShare *stayShare = [YKSStayShare newStayShareFromJSON:dict error:nil];
            
            successBlock(stayShare, operation);
            
        } else {
            
            failureBlock(operation, nil);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)updateStatusForStayShareWithId:(NSNumber *)stayShareId
                                stayId:(NSNumber *)stayId
                                status:(NSString *)status
                               success:(void (^)(AFHTTPRequestOperation *))successBlock
                               failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURlForStayShareWithId:stayShareId stayId:stayId];
    
    NSDictionary *params = @{
                             @"status":status
                             };
    
    [[YKSHTTPClient operationManager] PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)getUserInvitesForUserId:(NSNumber *)userId
                        success:(void (^)(NSArray *, AFHTTPRequestOperation *))successBlock
                        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForUserInvitesWithUserId:userId];
    
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *userInvitesJSONArray;
        
        id jsonObj = responseObject[@"response_body"][@"invites"];
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            userInvitesJSONArray = jsonObj[@"invites"];
        } else {
            userInvitesJSONArray = jsonObj;
        }
        
        NSError *error = nil;
        NSArray *userInvites = [YKSUserInvite newUserInvitesFromJSON:userInvitesJSONArray error:&error];
        
        if (!error) {
            successBlock(userInvites, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)createUserInviteForStayId:(NSNumber *)stayId
                         byUserId:(NSNumber *)userId
                     withUserForm:(NSDictionary *)form
                          success:(void (^)(NSNumber *, AFHTTPRequestOperation *))successBlock
                          failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForUserInvitesWithUserId:userId];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:form];
    [params setObject:stayId forKey:@"related_stay_id"];
    
    [[YKSHTTPClient operationManager] POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *inviteLocation = operation.response.allHeaderFields[@"Location"];
        
        if (inviteLocation && inviteLocation.length > 0) {
            
            NSURL *url = [NSURL URLWithString:inviteLocation];
            NSString *inviteIdString = [url.path lastPathComponent];
            NSNumber *inviteId = @([inviteIdString integerValue]);
            
            successBlock(inviteId, operation);
            
        } else {
            
            failureBlock(operation, nil);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)deleteUserInviteWithId:(NSNumber *)inviteId
                        userId:(NSNumber *)userId
                       success:(void (^)(AFHTTPRequestOperation *))successBlock
                       failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForUserInviteWithId:inviteId userId:userId];
    
    [[YKSHTTPClient operationManager] DELETE:url parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        failureBlock(operation, error);
    }];
}

+ (void)getContactsForUserId:(NSNumber *)userId
                     success:(void (^)(NSArray *, AFHTTPRequestOperation *))successBlock
                     failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForContactsForUserId:userId];
    
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *contactsJSONArray = responseObject[@"response_body"][@"contacts"];
        
        NSError *error = nil;
        NSArray *contacts = [YKSContact newContactsFromJSON:contactsJSONArray error:&error];
        
        if (!error) {
            successBlock(contacts, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)deleteContactWithId:(NSNumber *)contactId
                     userId:(NSNumber *)userId
                    success:(void (^)(AFHTTPRequestOperation *))successBlock
                    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForContactsWithId:contactId userId:userId];
    
    [[YKSHTTPClient operationManager] DELETE:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}

+ (void)updateUserWithForm:(NSDictionary *)form
                    userId:(NSNumber *)userId
                   success:(void (^)(AFHTTPRequestOperation *))successBlock
                   failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock {
    
    NSString *url = [self apiURLForUserWithId:userId];
    
    [[YKSHTTPClient operationManager] PUT:url parameters:form success:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(operation, error);
    }];
}


+ (void)updatePasswordForUserId:(NSNumber *)userId
                    oldPassword:(NSString *)oldPwd
                    newPassword:(NSString *)newPwd
                        success:(void (^)(AFHTTPRequestOperation *))successBlock
                        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock {
    
    NSString *url = [self apiURLForUpdatePasswordWith:userId];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:oldPwd forKey:@"old_password"];
    [params setObject:newPwd forKey:@"new_password"];
    
    [[YKSHTTPClient operationManager] POST:url parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        successBlock(operation);
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        failureBlock(operation, error);
    }];
}






@end
