//
//  YKSPrimaryYMan.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSPrimaryYMan.h"
#import "YKSStay.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

@implementation YKSPrimaryYMan

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"macAddress": @"mac_address",
             @"isMainRoom": @"is_main_room"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSArray *)newPrimaryYMenFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSPrimaryYMan.class fromJSONArray:JSONArray error:error];
}

+ (YKSPrimaryYMan *)newPrimaryYManFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSPrimaryYMan.class fromJSONDictionary:JSONDictionary error:error];
}

- (NSData *)binaryMacAddress {
   
    return [YKSBinaryHelper binaryFromHexString:self.macAddress];
    
}


@end
