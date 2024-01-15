//
//  YKSContactInfo.m
//  yEngine
//
//  Created by Manny Singh on 10/5/15.
//
//

#import "YKSContactInfo.h"
#import "YKSUserInfo.h"
#import "YKSConstants.h"

@interface YKSContactInfo()

@property (nonatomic, strong) NSNumber * contactId;
@property (nonatomic, strong) YKSUserInfo * user;

@end

@implementation YKSContactInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSContactInfo alloc] initWithJSONDictionary:dictionary];
}

+ (NSArray *)newContactsWithJSONArray:(NSArray *)array
{
    NSMutableArray *listOfContactInfos = [NSMutableArray new];
    [array enumerateObjectsUsingBlock:^(NSDictionary *contactJSON, NSUInteger idx, BOOL *stop) {
        
        YKSContactInfo *contactInfo = [YKSContactInfo newWithJSONDictionary:contactJSON];
        [listOfContactInfos addObject:contactInfo];
        
    }];
    return listOfContactInfos;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.contactId = NILIFNULL(dictionary[@"id"]);
    
    if ([dictionary[@"user"] isKindOfClass:[NSDictionary class]]) {
        self.user = [YKSUserInfo newWithJSONDictionary:dictionary[@"user"]];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    
    if ([object isKindOfClass:[YKSContactInfo class]]) {
        
        YKSContactInfo *contactInfo = (YKSContactInfo *)object;
        
        if (self.contactId) {
            
            if ([self.contactId isEqualToNumber:contactInfo.contactId]) {
                
                return YES;
                
            } else {
                
                return NO;
            }
            
        } else if (self.user.email &&
                   [self.user.email isEqualToString:contactInfo.user.email]) {
            
            return YES;
        }
        
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return [self.contactId hash];
}

@end
