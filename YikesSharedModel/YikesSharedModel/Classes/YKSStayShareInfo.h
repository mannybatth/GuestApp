//
//  YKSStayShareInfo.h
//  YikesEngine
//
//  Created by Manny Singh on 9/3/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YKSUserInfo, YKSStayInfo;

@interface YKSStayShareInfo : NSObject

@property (nonatomic, strong, readonly) NSNumber * stayShareId;
@property (nonatomic, strong, readonly) NSString * status;
@property (nonatomic, strong, readonly) YKSStayInfo * stay;
@property (nonatomic, strong, readonly) YKSUserInfo * primaryGuest;
@property (nonatomic, strong, readonly) YKSUserInfo * secondaryGuest;

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary;
+ (NSArray *)newStaySharesWithJSONArray:(NSArray *)array;

@end
