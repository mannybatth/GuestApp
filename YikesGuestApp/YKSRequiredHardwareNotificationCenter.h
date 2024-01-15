//
//  YKSDebugNotificationCenter.h
//  yikes
//
//  Created by royksopp on 2015-05-13.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const YKS_REQUIRED_HARDWARE_NO_BLUETOOTH;
FOUNDATION_EXPORT NSString *const YKS_REQUIRED_HARDWARE_NO_INTERNET;
FOUNDATION_EXPORT NSString *const YKS_REQUIRED_HARDWARE_NO_LOCATION_SERVICE;
FOUNDATION_EXPORT NSString *const YKS_REQUIRED_HARDWARE_NO_BACKGR_APP_REFRESH;
FOUNDATION_EXPORT NSString *const YKS_REQUIRED_HARDWARE_NO_PUSH_NOTIFICATIONS;

@protocol YKSRequiredHardwareNotificatioCenterDelegate;
@protocol YKSRequiredHardwareNotificatioCenterNewMessageDelegate;


@interface YKSRequiredHardwareNotificationCenter : NSObject

@property (nonatomic, weak) id<YKSRequiredHardwareNotificatioCenterDelegate> requiredHardwareDelegate;
@property (nonatomic, weak) id<YKSRequiredHardwareNotificatioCenterNewMessageDelegate> requiredHardwareMessagesAvailableDelegate;


+ (YKSRequiredHardwareNotificationCenter *)sharedCenter;


- (void)readRequiredHardwareState;
- (NSArray *)requireHardwareCurrentMessages;
- (void)callFromEngineIsMissingServices:(NSArray *)missingServices;

@end



@protocol YKSRequiredHardwareNotificatioCenterDelegate <NSObject>

@required
- (void)requiredHardwareUpdate:(NSUInteger)missingRequiredHardwareCount;

@end;



@protocol YKSRequiredHardwareNotificatioCenterNewMessageDelegate <NSObject>

@required
- (void)requiredHardwareNewMessagesAvailable:(NSSet *)currentStates;

@end
