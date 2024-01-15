//
//  YikesSharedModel.h
//  YikesSharedModel
//
//  Created by mba on 2016-02-29.
//  Copyright © 2016 Yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for YikesSharedModel.
FOUNDATION_EXPORT double YikesSharedModelVersionNumber;

//! Project version string for YikesSharedModel.
FOUNDATION_EXPORT const unsigned char YikesSharedModelVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <YikesSharedModel/PublicHeader.h>

#ifndef DLog
#if DEBUG
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
// in Release builds, don't log Debug logs
#define DLog(...) do { } while (0)
#endif
#endif

#import "YKSUserInfo.h"
#import "YKSStayInfo.h"
#import "YKSAddressInfo.h"
#import "YKSAmenityInfo.h"
#import "YKSStayShareInfo.h"
#import "YKSUserInviteInfo.h"
#import "YKSError.h"
#import "YKSContactInfo.h"
#import "YKSConstants.h"
#import "YikesEngineProtocol.h"
#import "YKSDateHelper.h"
#import "YKSDeveloperHelper.h"
#import "NSString+YKSString.h"
