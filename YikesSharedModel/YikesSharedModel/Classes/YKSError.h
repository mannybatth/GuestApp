//
//  YKSError.h
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSConstants.h"

@interface YKSError : NSObject

@property (nonatomic, readonly) YKSErrorCode errorCode;
@property (nonatomic, strong, readonly) NSString * errorDescription;
@property (nonatomic, strong, readonly) NSError * nsError;
@property (nonatomic, strong) NSDictionary * userInfo;
@property (nonatomic, assign) Boolean reportOnCrashlytics;
@property (nonatomic, assign) Boolean logEventOnCrashlytics;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventCustomAttributes;

+ (instancetype)newWithErrorCode:(YKSErrorCode)errorCode errorDescription:(NSString *)errorDescription;
+ (instancetype)newWithErrorCode:(YKSErrorCode)errorCode errorDescription:(NSString *)errorDescription nsError:(NSError *)nsError;

- (NSString *)description;

@end
