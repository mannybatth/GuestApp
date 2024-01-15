//
//  YKSAssetsHelper.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAssetsHelper.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation YKSAssetsHelper

+ (NSString *)hotelDashboardImageURLForStay:(YKSStayInfo *)stay {
    
    // return dashboard image url by screen scale
    if ([[UIScreen mainScreen] scale] == 1.0) {
        
        // return 1x if found, or else in order 2x, then 3x
        if (stay.dashboardImageURL1x) {
            return stay.dashboardImageURL1x;
            
        } else if (stay.dashboardImageURL2x) {
            return stay.dashboardImageURL2x;
        }
        return stay.dashboardImageURL3x;
        
    } else if ([[UIScreen mainScreen] scale] == 2.0) {
        
        // return 2x if found, or else in order 1x, then 3x
        if (stay.dashboardImageURL2x) {
            return stay.dashboardImageURL2x;
            
        } else if (stay.dashboardImageURL1x) {
            return stay.dashboardImageURL1x;
        }
        return stay.dashboardImageURL3x;
        
    }
    
    // return 3x if found, or else in order 2x, then 1x
    if (stay.dashboardImageURL3x) {
        return stay.dashboardImageURL3x;
        
    } else if (stay.dashboardImageURL2x) {
        return stay.dashboardImageURL2x;
    }
    return stay.dashboardImageURL1x;
}

+ (BOOL)checkIfDashboardImageURLhasChangedForStay:(YKSStayInfo *)stay {
    
    NSString *hotelDashboardImageURL = [YKSAssetsHelper hotelDashboardImageURLForStay:stay];
    NSString *hotelDashboardImageKey = [NSString stringWithFormat:@"%@_dashboardImageURL", stay.hotelName];
    NSString *previousDashboardImageURL = [[NSUserDefaults standardUserDefaults] objectForKey:hotelDashboardImageKey];
    
    BOOL isNewImage = NO;
    if (![hotelDashboardImageURL isEqualToString:previousDashboardImageURL] ||
        ![previousDashboardImageURL isEqualToString:hotelDashboardImageURL]) {
        
        isNewImage = YES;
        NSString *previousCacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:previousDashboardImageURL]];
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:previousCacheKey completion:^(BOOL isInCache) {
            if (isInCache) {
                
                // remove old image from cache
                [[SDImageCache sharedImageCache] removeImageForKey:previousCacheKey];
            }
        }];
        
        [[NSUserDefaults standardUserDefaults] setObject:hotelDashboardImageURL forKey:hotelDashboardImageKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    return isNewImage;
}

+ (UIImage *)backgroundImageForHotelName:(NSString *)hotelName {
    
    if ([hotelName rangeOfString:@"CityFlatsHotel" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        return [UIImage imageNamed:@"CFH GR 1"];
        
    } else if ([hotelName rangeOfString:@"Best Western" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        return [UIImage imageNamed:@"BW 1"];
        
    }
    
    return [UIImage imageNamed:@"hotel_bg"];
    
}

@end
