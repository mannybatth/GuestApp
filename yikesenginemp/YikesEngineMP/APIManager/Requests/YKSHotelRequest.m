//
//  YKSHotelRequest.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSHotelRequest.h"
#import "YKSHotel.h"

@implementation YKSHotelRequest

+ (void)getHotelWithId:(NSNumber *)hotelId
               success:(void (^)(YKSHotel *, AFHTTPRequestOperation *))successBlock
               failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureBlock
{
    NSString *url = [self apiURLForHotelWithId:hotelId];
    
    [[YKSHTTPClient operationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *hotelJSON = responseObject[@"response_body"][@"hotel"];
        
        NSError *error = nil;
        YKSHotel *hotel = [YKSHotel newHotelFromJSON:hotelJSON error:&error];
        
        if (!error) {
            successBlock(hotel, operation);
        } else {
            failureBlock(operation, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        failureBlock(operation, error);
        
    }];
}

@end
