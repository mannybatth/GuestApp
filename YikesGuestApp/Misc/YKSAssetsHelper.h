//
//  YKSAssetsHelper.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSAssetsHelper : NSObject

+ (NSString *)hotelDashboardImageURLForStay:(YKSStayInfo *)stay;
+ (BOOL)checkIfDashboardImageURLhasChangedForStay:(YKSStayInfo *)stay;
+ (UIImage *)backgroundImageForHotelName:(NSString *)hotelName;

@end
