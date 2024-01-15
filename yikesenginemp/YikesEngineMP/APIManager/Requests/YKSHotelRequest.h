//
//  YKSHotelRequest.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Request class that includes API calls involving a hotel.
 */

#import "YKSRequest.h"

@class YKSHotel;

@interface YKSHotelRequest : YKSRequest

+ (void)getHotelWithId:(NSNumber *)hotelId
               success:(void(^)(YKSHotel *hotel, AFHTTPRequestOperation *operation))successBlock
               failure:(void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;
@end
