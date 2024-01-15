//
//  YKSStayShare.m
//  yEngine
//
//  Created by Manny Singh on 9/2/15.
//
//

#import "YKSStayShare.h"
#import "YKSUser.h"
#import "YKSStay.h"

@implementation YKSStayShare

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"stayShareId": @"id",
             @"status": @"status",
             @"stay": @"stay",
             @"primaryGuest": @"primary_guest",
             @"secondaryGuest": @"secondary_guest"
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // Store a value that needs to be determined locally upon initialization.
    
    return self;
}

+ (NSValueTransformer *)stayJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSStay.class];
}

+ (NSValueTransformer *)primaryGuestJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSUser.class];
}

+ (NSValueTransformer *)secondaryGuestJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:YKSUser.class];
}

+ (NSArray *)newStaySharesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelsOfClass:YKSStayShare.class fromJSONArray:JSONArray error:error];
}

+ (YKSStayShare *)newStayShareFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error
{
    return [MTLJSONAdapter modelOfClass:YKSStayShare.class fromJSONDictionary:JSONDictionary error:error];
}

@end
