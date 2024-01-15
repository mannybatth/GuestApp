//
//  YKSDeviceHelper.h
//  yEngine
//
//  Created by Manny Singh on 9/29/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YKSDeviceHelper : NSObject

@property (nonatomic, strong) NSString *clientVersionInfo;

+ (instancetype)sharedHelper;

+ (NSString *)osVersion;
+ (NSString *)engineVersion;
+ (NSString *)guestAppVersion;
+ (NSString *)guestAppBuild;
+ (NSString *)fullGuestAppVersion;
+ (NSString *)phoneModel;

@end
