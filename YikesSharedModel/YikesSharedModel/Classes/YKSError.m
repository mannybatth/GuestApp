//
//  YKSError.m
//  YikesEngine
//
//  Created by Manny Singh on 4/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSError.h"

@interface YKSError ()

@property (nonatomic, readwrite) YKSErrorCode errorCode;
@property (nonatomic, strong, readwrite) NSString * errorDescription;
@property (nonatomic, strong) NSError * nsError;

@end

@implementation YKSError

+ (instancetype)newWithErrorCode:(YKSErrorCode)errorCode
                errorDescription:(NSString *)errorDescription
{
    return [self newWithErrorCode:errorCode errorDescription:errorDescription nsError:[NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDescription, nil)}]];
}

+ (instancetype)newWithErrorCode:(YKSErrorCode)errorCode
                errorDescription:(NSString *)errorDescription
                         nsError:(NSError *)nsError
{
    YKSError *error = [[YKSError alloc] initWithErrorCode:errorCode
                                         errorDescription:errorDescription];
    error.nsError = nsError;
//    YKSLogAPIError(@"%@", error);
    return error;
}

- (instancetype)initWithErrorCode:(YKSErrorCode)errorCode errorDescription:(NSString *)errorDescription
{
    // default report to false:
    return [self initWithErrorCode:errorCode errorDescription:errorDescription reportOnCrashlytics:false];
}

- (instancetype)initWithErrorCode:(YKSErrorCode)errorCode errorDescription:(NSString *)errorDescription logEventOnCrashlytics:(Boolean)log eventName:(NSString *)name {
    self = [self initWithErrorCode:errorCode errorDescription:errorDescription];
    self.logEventOnCrashlytics = YES;
    self.eventName = name;
    return self;
}

- (instancetype)initWithErrorCode:(YKSErrorCode)errorCode errorDescription:(NSString *)errorDescription reportOnCrashlytics:(Boolean)report {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.errorCode = errorCode;
    self.errorDescription = errorDescription;
    self.reportOnCrashlytics = report;
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ Error code %lu ", self.errorDescription, (unsigned long)self.errorCode];
}

@end
