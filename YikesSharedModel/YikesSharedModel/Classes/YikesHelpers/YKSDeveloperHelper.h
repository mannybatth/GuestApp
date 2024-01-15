//
//  YKSDeveloperHelper.h
//  YikesSharedModel
//
//  Created by Alexandar Dimitrov on 2016-08-31.
//  Copyright © 2016 Yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSDeveloperHelper : NSObject

+ (BOOL)isDevQaProdUser:(NSString*)email;
+ (BOOL)isQaProdUser: (NSString*)email;

@end
