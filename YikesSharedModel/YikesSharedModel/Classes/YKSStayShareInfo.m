//
//  YKSStayShareInfo.m
//  YikesEngine
//
//  Created by Manny Singh on 9/3/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSStayShareInfo.h"
#import "YKSStayInfo.h"
#import "YKSUserInfo.h"

@interface YKSStayShareInfo()

@property (nonatomic, strong) NSNumber * stayShareId;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, strong) YKSStayInfo * stay;
@property (nonatomic, strong) YKSUserInfo * primaryGuest;
@property (nonatomic, strong) YKSUserInfo * secondaryGuest;

@end

@implementation YKSStayShareInfo

+ (instancetype)newWithJSONDictionary:(NSDictionary *)dictionary
{
    return [[YKSStayShareInfo alloc] initWithJSONDictionary:dictionary];
}

+ (NSArray *)newStaySharesWithJSONArray:(NSArray *)array
{
    NSMutableArray *listOfStayShareInfos = [NSMutableArray new];
    [array enumerateObjectsUsingBlock:^(NSDictionary *stayShareJSON, NSUInteger idx, BOOL *stop) {
        
        YKSStayShareInfo *stayShareInfo = [YKSStayShareInfo newWithJSONDictionary:stayShareJSON];
        [listOfStayShareInfos addObject:stayShareInfo];
        
    }];
    return listOfStayShareInfos;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stayShareId = NILIFNULL(dictionary[@"id"]);
    self.status = NILIFNULL(dictionary[@"status"]);
    
    if ([dictionary[@"stay"] isKindOfClass:[NSDictionary class]]) {
        self.stay = [YKSStayInfo newWithJSONDictionary:dictionary[@"stay"]];
    }
    
    if ([dictionary[@"primary_guest"] isKindOfClass:[NSDictionary class]]) {
        self.primaryGuest = [YKSUserInfo newWithJSONDictionary:dictionary[@"primary_guest"]];
    }
    
    if ([dictionary[@"secondary_guest"] isKindOfClass:[NSDictionary class]]) {
        self.secondaryGuest = [YKSUserInfo newWithJSONDictionary:dictionary[@"secondary_guest"]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"StayId: %@, Status: %@, Primary: %@, Secondary: %@",
            self.stay.stayId,
            self.status,
            self.primaryGuest.email,
            self.secondaryGuest.email];
}

@end
