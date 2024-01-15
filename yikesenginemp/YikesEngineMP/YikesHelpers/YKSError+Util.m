//
//  YKSError+Util.m
//  YikesEnginePod
//
//  Created by Manny Singh on 6/16/15.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

#import "YKSError+Util.h"
#import "YKSLevelLogger.h"
#import "AFHTTPRequestOperation.h"
#import "MTLTransformerErrorHandling.h"

@import YikesSharedModel;

@implementation YKSError (Util)

+ (YKSError *)yikesErrorFromOperation:(AFHTTPRequestOperation *)operation
{
    NSHTTPURLResponse *response = operation.response;
    
    YKSError *yikesError;
    
    if (response) {
        switch (response.statusCode) {
                
            case 400:
                return [YKSError newWithErrorCode:kYKSServerSidePayloadValidation
                                 errorDescription:kYKSErrorServerSidePayloadValidationDescription
                                          nsError:operation.error];
                break;
                
            case 401:
                return [YKSError newWithErrorCode:kYKSUserNotAuthorized
                                 errorDescription:kYKSErrorUserNotAuthorizedDescription];
                break;
                
            case 403:
                return [YKSError newWithErrorCode:kYKSUserForbidden
                                 errorDescription:kYKSErrorUserForbiddenDescription];
                break;
                
            case 409:
                return [YKSError newWithErrorCode:kYKSResourceConflict
                                 errorDescription:kYKSErrorResourceConflictDescription];
                break;
                
            default:
                break;
        }
    }
    
    if (operation.error) {
        
        yikesError = [YKSError yikesErrorFromNSError:operation.error];
        if (yikesError) {
            return yikesError;
        }
        
    }
    
    return [YKSError unknownError];
}

+ (YKSError *)yikesErrorFromNSError:(NSError *)error
{
    if (error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]) {
        
        return [YKSError newWithErrorCode:kYKSUnknown
                         errorDescription:kYKSErrorFailedToTransformDataDescription];
        
    } else if ([error.domain isEqual:NSURLErrorDomain]) {
        
        switch (error.code) {
                
            case NSURLErrorCannotFindHost:
                return [YKSError newWithErrorCode:kYKSFailureConnectingToYikesServer
                                 errorDescription:kYKSErrorFailureConnectingToYikesServerDescription];
                break;
                
            default: {
                NSString *desc = [NSString stringWithFormat:@"%@ URLErrorCode: %li",
                                  error.localizedDescription, (long)error.code];
                
                return [YKSError newWithErrorCode:kYKSUnknown
                                 errorDescription:desc];
                break;
            }
        }
        
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        
        switch (error.code) {
            case NSPropertyListReadCorruptError: {
                NSString *desc = [NSString stringWithFormat:@"JSON parsing error. CocoaErrorCode: %li",
                                  (long)error.code];
                
                return [YKSError newWithErrorCode:kYKSUnknown
                                 errorDescription:desc];
                break;
            }
                
            default: {
                NSString *desc = [NSString stringWithFormat:@"%@ CocoaErrorCode: %li",
                                  error.localizedDescription, (long)error.code];
                
                return [YKSError newWithErrorCode:kYKSUnknown
                                 errorDescription:desc];
                break;
            }
        }
        
    } else if ([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
        
        NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        YKSError *yikesError = [YKSError newWithErrorCode:kYKSUnknown errorDescription:dataStr nsError:error];
        return yikesError;
        
    }
    
    return nil;
}

+ (YKSError *)unknownError
{
    return [YKSError newWithErrorCode:kYKSUnknown
                     errorDescription:kYKSErrorUnknownDescription];
}

@end
