//
//  YKSSession.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Session model used to store currentUser, currentStays, & sessionCookie
 */

#import "YKSModel.h"

@class YKSUser;

@interface YKSSession : YKSModel

@property (nonatomic, strong) YKSUser *currentUser;

/**
 *  Create new YKSSession instance.
 */
- (instancetype)initWithUser:(YKSUser *)user;

@end
