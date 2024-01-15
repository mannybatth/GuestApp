//
//  YKSContact.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/26/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSContact.h"
#import "YKSUser.h"

@implementation YKSContact

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"contactId": @"id",
             @"user": @"user"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSValueTransformer *)userJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSUser.class];
}

+ (NSArray *)newContactsFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSContact.class fromJSONArray:JSONArray error:error];
}

+ (YKSContact *)newContactFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSContact.class fromJSONDictionary:JSONDictionary error:error];
}

@end
