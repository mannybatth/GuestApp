//
//  YKSDeviceHelper.m
//  yEngine
//
//  Created by Manny Singh on 9/29/15.
//
//

#import "YKSDeviceHelper.h"

#import <sys/utsname.h>

@implementation YKSDeviceHelper

+ (instancetype)sharedHelper
{
    static YKSDeviceHelper *_sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHelper = [[YKSDeviceHelper alloc] init];
    });
    
    return _sharedHelper;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self buildClientVersionInfo];
    
    return self;
}

- (void)buildClientVersionInfo {
    
    NSDictionary *info = @{
                           @"os": @"ios",
                           @"osV": [YKSDeviceHelper osVersion],
                           @"EngineV": [YKSDeviceHelper engineVersion],
                           @"GAppV": [YKSDeviceHelper guestAppVersion],
                           @"GAppB": [YKSDeviceHelper guestAppBuild],
                           @"model": [YKSDeviceHelper phoneModel]
                           };
    
    NSMutableString *clientInfo = [[NSMutableString alloc] init];
    [info enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, NSString*  _Nonnull value, BOOL * _Nonnull stop) {
        [clientInfo appendString:[NSString stringWithFormat:@"%@:%@;", key, value]];
    }];
    self.clientVersionInfo = clientInfo;
    
}

+ (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion;
}

+ (NSString *)engineVersion {
    NSBundle *podbundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [podbundle URLForResource:@"YikesEngineMP" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    
    if (bundle) {
        // using a .framework
        return [NSString stringWithFormat:@"%@ b%@", [bundle infoDictionary][@"CFBundleShortVersionString"], [bundle infoDictionary][@"CFBundleVersion"]];
    }
    else {
        return @"";
    }
}

+ (NSString *)guestAppVersion {
    NSString *versionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    return versionString;
}

+ (NSString *)guestAppBuild {
    NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    return buildNumber;
}

+ (NSString *)fullGuestAppVersion {
    NSString *fullVersion = [NSString stringWithFormat:@"v%@ (%@)", [YKSDeviceHelper guestAppVersion], [YKSDeviceHelper guestAppBuild]];
    
#ifdef DEBUG
    fullVersion = [fullVersion stringByAppendingString:@" d"];
#endif
    
    return fullVersion;
}

+ (NSString *)phoneModel {
    
    NSDictionary *modelManifest = @{
                                    @"iPhone": @{
                                            // 1st Gen
                                            @[@(1), @(1)]: @"iPhone1",
                                            
                                            // 3G
                                            @[@(1), @(2)]: @"iPhone3G",
                                            
                                            // 3GS
                                            @[@(2), @(1)]: @"iPhone3GS",
                                            
                                            // 4
                                            @[@(3), @(1)]: @"iPhone4",
                                            @[@(3), @(2)]: @"iPhone4",
                                            @[@(3), @(3)]: @"iPhone4",
                                            
                                            // 4S
                                            @[@(4), @(1)]: @"iPhone4S",
                                            
                                            // 5
                                            @[@(5), @(1)]: @"iPhone5",
                                            @[@(5), @(2)]: @"iPhone5",
                                            
                                            // 5C
                                            @[@(5), @(3)]: @"iPhone5C",
                                            @[@(5), @(4)]: @"iPhone5C",
                                            
                                            // 5S
                                            @[@(6), @(1)]: @"iPhone5S",
                                            @[@(6), @(2)]: @"iPhone5S",
                                            
                                            // 6 Plus
                                            @[@(7), @(1)]: @"iPhone6Plus",
                                            
                                            // 6
                                            @[@(7), @(2)]: @"iPhone6",
                                            
                                            // 6S Plus
                                            @[@(8), @(2)]: @"iPhone6SPlus",
                                            
                                            // 6S
                                            @[@(8), @(1)]: @"iPhone6S"
                                            },
                                    @"iPad": @{
                                            // 1
                                            @[@(1), @(1)]: @"iPad1",
                                            
                                            // 2
                                            @[@(2), @(1)]: @"iPad2",
                                            @[@(2), @(2)]: @"iPad2",
                                            @[@(2), @(3)]: @"iPad2",
                                            @[@(2), @(4)]: @"iPad2",
                                            
                                            // Mini
                                            @[@(2), @(5)]: @"iPadMini1",
                                            @[@(2), @(6)]: @"iPadMini1",
                                            @[@(2), @(7)]: @"iPadMini1",
                                            
                                            // 3
                                            @[@(3), @(1)]: @"iPad3",
                                            @[@(3), @(2)]: @"iPad3",
                                            @[@(3), @(3)]: @"iPad3",
                                            
                                            // 4
                                            @[@(3), @(4)]: @"iPad4",
                                            @[@(3), @(5)]: @"iPad4",
                                            @[@(3), @(6)]: @"iPad4",
                                            
                                            // Air
                                            @[@(4), @(1)]: @"iPadAir1",
                                            @[@(4), @(2)]: @"iPadAir1",
                                            @[@(4), @(3)]: @"iPadAir1",
                                            
                                            // Mini 2
                                            @[@(4), @(4)]: @"iPadMini2",
                                            @[@(4), @(5)]: @"iPadMini2",
                                            @[@(4), @(6)]: @"iPadMini2",
                                            
                                            // Mini 3
                                            @[@(4), @(7)]: @"iPadMini3",
                                            @[@(4), @(8)]: @"iPadMini3",
                                            @[@(4), @(9)]: @"iPadMini3",
                                            
                                            // Air 2
                                            @[@(5), @(3)]: @"iPadAir2",
                                            @[@(5), @(4)]: @"iPadAir2"
                                            },
                                    @"iPod": @{
                                            // 1st Gen
                                            @[@(1), @(1)]: @"iPodTouch1",
                                            
                                            // 2nd Gen
                                            @[@(2), @(1)]: @"iPodTouch2",
                                            
                                            // 3rd Gen
                                            @[@(3), @(1)]: @"iPodTouch3",
                                            
                                            // 4th Gen
                                            @[@(4), @(1)]: @"iPodTouch4",
                                            
                                            // 5th Gen
                                            @[@(5), @(1)]: @"iPodTouch5"
                                            }
                                    };
    
    NSString *model = @"Unknown";
    NSString *systemInfoString = [YKSDeviceHelper rawSystemInfoString];
    
    if ([systemInfoString isEqualToString:@"i386"] || [systemInfoString isEqualToString:@"x86_64"]) {
        return @"Simulator";
    }
    
    NSUInteger positionOfFirstInteger = [systemInfoString rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location;
    NSUInteger positionOfComma = [systemInfoString rangeOfString:@","].location;
    
    NSUInteger major = 0;
    NSUInteger minor = 0;
    
    if (positionOfComma != NSNotFound) {
        major = [[systemInfoString substringWithRange:NSMakeRange(positionOfFirstInteger, positionOfComma - positionOfFirstInteger)] integerValue];
        minor = [[systemInfoString substringFromIndex:positionOfComma + 1] integerValue];
    }
    
    for (NSString *key in modelManifest) {
    
        if ([systemInfoString hasPrefix:key]) {
            NSString *value = modelManifest[key][@[@(major), @(minor)]];
            if (value) {
                model = [NSString stringWithString:value];
            }
        }
        
    }
    
    return model;
}

+ (NSString *)rawSystemInfoString {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end
