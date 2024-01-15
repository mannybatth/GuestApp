//
//  YKSContactInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 10/5/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YKSUserInfo;

@interface YKSContactInfo : NSObject

@property (nonatomic, strong, readonly) NSNumber * contactId;
@property (nonatomic, strong, readonly) YKSUserInfo * user;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;
+ (NSArray *)newContactsWithJSONArray:(NSArray *)array;

@end
