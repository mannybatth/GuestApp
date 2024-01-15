//
//  YKSUserInviteInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 9/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSUserInviteInfo : NSObject

@property (nonatomic, strong, readonly) NSNumber * inviteId;
@property (nonatomic, strong, readonly) NSString * firstName;
@property (nonatomic, strong, readonly) NSString * lastName;
@property (nonatomic, strong, readonly) NSString * email;
@property (nonatomic, strong, readonly) NSNumber * relatedStayId;
@property (nonatomic, readonly) BOOL isAccepted;
@property (nonatomic, readonly) BOOL isDeclined;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;
+ (NSArray *)newUserInvitesWithJSONArray:(NSArray *)array;

@end
