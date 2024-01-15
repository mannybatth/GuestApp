//
//  YKSError+Util.h
//  YikesEnginePod
//
//  Created by Manny Singh on 6/16/15.
//  Copyright (c) 2015 Elliot Sinyor. All rights reserved.
//

@import YikesSharedModel;

@class AFHTTPRequestOperation;

@interface YKSError (Util)

+ (YKSError *)yikesErrorFromOperation:(AFHTTPRequestOperation *)operation;
+ (YKSError *)yikesErrorFromNSError:(NSError *)error;
+ (YKSError *)unknownError;

@end
