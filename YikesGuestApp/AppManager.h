//
//  AppManager.h
//  yikes
//
//  Created by Alexandar Dimitrov on 2014-11-12.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@import PubNub;

@interface AppManager : NSObject

+ (AppManager *)sharedInstance;

#pragma mark - Push Notifications
- (void)registerForPushNotifications;
- (void)unregisterForPushNotifications;
- (void)unsubscribeFromAllPubNubChannelsCompletion:(void(^)(NSError *error))completion;

- (void)configureAndStartPubNub;
- (void)sendPushNotificationWithAlert:(NSString *)message;

- (NSString *)monitoringChannel;

#pragma mark - App infos
+ (NSString *)fullVersionString;

- (BOOL)isIPhone6plus;
- (BOOL)isIPhone4size;
- (BOOL)isIPhone5size;


- (void)setFabricUserInfo;


@end
