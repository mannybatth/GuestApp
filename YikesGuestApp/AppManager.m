//
//  AppManager.m
//  yikes
//
//  Created by Alexandar Dimitrov on 2014-11-12.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "AppManager.h"
#import "YKSTestAccounts.h"

#define deviceToken AppDelegate.pushDeviceToken

@interface AppManager () <PNObjectEventListener>

@property (nonatomic, strong) PubNub *pubNub;
@property (nonatomic, strong) NSArray *channelsToSubscribe;
@property (nonatomic, strong) NSString *my_channel;
@property (nonatomic, strong) NSString *monitoringChannel;

@property (nonatomic, assign) NSInteger pubNubSubscribeRetries;
@property (nonatomic, assign, readonly) NSInteger maxPubNubSubscribeRetries;

@end

@implementation AppManager

@synthesize pubNub, my_channel;

+ (id)sharedInstance {
    static dispatch_once_t pred;
    static AppManager *appManagerInstance = nil;
    
    dispatch_once(&pred, ^{
        appManagerInstance = [[self alloc] init];
    });
    
    return appManagerInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        _pubNubSubscribeRetries = 0;
        _maxPubNubSubscribeRetries = 3;
    }
    
    return self;
}

#pragma mark - NSNotificationCenter calls

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self verifyPubNubSubscriptions];
}

#pragma mark - Push Notification Service

/**
 * This is the start of the Push Notifications setup. The shared Application first needs to call registerForRemoteNotifications to
 * get a callback with the device token. That device token can then be used to uniquely identify a device on PubNub and 
 * have the APNS send direct notifications to that specific device.
 */
- (void)registerForPushNotifications {
    
    [[YikesEngine sharedInstance] logMessage:@"[PN] RegisterForPushNotifications called..."];
    
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        
    }
}

- (void)unregisterForPushNotifications {
    if (!deviceToken) {
        // need to first get ahold of the push device token:
        [[AppManager sharedInstance] registerForPushNotifications];
    }
    else {
        // already got the deviceToken:
        [self stopPubNubWithCompletion:^{
            [[UIApplication sharedApplication] unregisterForRemoteNotifications];
            // nil local copy
            deviceToken = nil;
        }];
    }
}

- (void) verifyPubNubSubscriptions {
    
    [[YikesEngine sharedInstance] logMessage:@"[PN] Verifying Pubnub subscriptions..."];
    
    if (!deviceToken && !pubNub) {
        // the device token failed the previous time, let's try again:
        [self registerForPushNotifications];
    }
    else if (deviceToken) {
        [self startPubNub];
    }
    else {
        CLS_LOG(@"Missing device token %@ or nil pubNub client: %@", deviceToken, [[[YikesEngine sharedEngine] userInfo] email]);
    }
}

- (PNConfiguration *)pubNubConfig {
    
#ifdef DEBUG
    
    PNConfiguration *myConfig = [PNConfiguration configurationWithPublishKey:@"pub-c-ad9ca7e5-a87a-4249-85b4-52f6d8f8d2a0"
                                                                subscribeKey:@"sub-c-23ea3282-abab-11e4-85c1-02ee2ddab7fe"];
    
#else
    //Only the subscribeKey is mandatory. Only include the publishKey if you intend to publish from this instance
    PNConfiguration *myConfig = [PNConfiguration configurationWithPublishKey:@"pub-c-379ac2e8-f358-49e8-8717-b212bf1d9339"
                                                                subscribeKey:@"sub-c-b2f9e276-d944-11e4-add5-0619f8945a4f"];
    
#endif
    
//    CLS_LOG(@"PNConfig:\n%@", myConfig);
    
    return myConfig;
}

/**
 * This will be call once the registerForRemoteNotificationTypes: returns successful in 
 * (void)application:didRegisterForRemoteNotificationsWithDeviceToken:
 * with the unique device token.
 */
- (void)configureAndStartPubNub {
    
    // Starting... reset the retries count:
    _pubNubSubscribeRetries = 0;
    
    if ([[YikesEngine sharedEngine] userInfo]) {
        
        [[YikesEngine sharedInstance] logMessage:@"[PN] Starting Pubnub..."];
        [self startPubNub];
    }
    else {
        [[YikesEngine sharedInstance] logMessage:@"[PN] Stopping Pubnub"];
        [self stopPubNubWithCompletion:nil];
    }
    
    
}

- (void)retryPubNubSubscription {
    if (_pubNubSubscribeRetries < _maxPubNubSubscribeRetries) {
        if (_pubNubSubscribeRetries < 0) _pubNubSubscribeRetries = 0;
        _pubNubSubscribeRetries ++;
        CLS_LOG(@"retryPubNubSubscription %@", @(_pubNubSubscribeRetries));
        [self startPubNub];
    }
    else {
        CLS_LOG(@"_maxPubNubSubscribeRetries reached - giving up");
    }
}

- (void)startPubNub {
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    NSString *phoneID = user.deviceId;
    
    if (!phoneID) {
        [AppDelegate fireDebugLocalNotification:@"No device_id found on current user\nCannot subscribe to the private PubNub channel"];
        NSLog(@"No PhoneID for current user - cannot subscribe to PubNub channel");
        return;
    }
    
    PNConfiguration *myConfig = [self pubNubConfig];
    
    if (myConfig) {
        
        // Setup the PubNub client and add this class as the listener:
        self.pubNub = [PubNub clientWithConfiguration:myConfig];
        [self.pubNub addListener:self];
        self.my_channel = [NSString stringWithFormat:@"%@", phoneID];
        
        self.channelsToSubscribe = [NSArray arrayWithObjects:my_channel, nil];
        
        if ([user.email isEqualToString:@"roger@yamm.ca"]) {
            self.channelsToSubscribe = [self.channelsToSubscribe arrayByAddingObject:self.monitoringChannel];
        }
        
        if ([[NSSet setWithArray:pubNub.channels] isEqualToSet:[NSSet setWithArray:self.channelsToSubscribe]]) {
            [[YikesEngine sharedInstance] logMessage:(@"[PN] Already subscribed to all channels - good to go!")];
        }
        else {
            [pubNub unsubscribeFromChannels:pubNub.channels withPresence:NO];
            // Subscribe on connect
            [[YikesEngine sharedInstance] logMessage:[NSString stringWithFormat:@"[PN] Subscribing to channels %@", self.channelsToSubscribe]];
            [pubNub subscribeToChannels:self.channelsToSubscribe withPresence:NO];
        }
    }
    
}

- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    
    if (status.operation == PNSubscribeOperation) {
        
        // Check whether received information about successful subscription or restore.
        if (status.category == PNConnectedCategory && status.category == PNReconnectedCategory) {
            
            // Status object for those categories can be casted to `PNSubscribeStatus` for use below.
            PNSubscribeStatus *subscribeStatus = (PNSubscribeStatus *)status;
            if (subscribeStatus.category == PNConnectedCategory) {
                
                // This is expected for a subscribe, this means there is no error or issue whatsoever.
                CLS_LOG(@"[Pubnub] All set, subscribed to all channels.");
            }
            else {
                
                /**
                 This usually occurs if subscribe temporarily fails but reconnects. This means there was
                 an error but there is no longer any issue.
                 */
            }
        }
        // Looks like some kind of issues happened while client tried to subscribe or disconnected from
        // network.
        else {
            
            PNErrorStatus *errorStatus = (PNErrorStatus *)status;
            if (errorStatus.category == PNAccessDeniedCategory) {
                
                /**
                 This means that PAM does allow this client to subscribe to this channel and channel group
                 configuration. This is another explicit error.
                 */
            }
            else if (errorStatus.category == PNUnexpectedDisconnectCategory) {
                
                /**
                 This is usually an issue with the internet connection, this is an error, handle
                 appropriately retry will be called automatically.
                 */
            }
            else {
                
                /**
                 More errors can be directly specified by creating explicit cases for other error categories
                 of `PNStatusCategory` such as `PNTimeoutCategory` or `PNMalformedFilterExpressionCategory` or
                 `PNDecryptionErrorCategory`
                 */
                
                if (status.category == PNTimeoutCategory) {
                    [self retryPubNubSubscription];
                }
            }
        }
    }
    else if (status.operation == PNUnsubscribeOperation) {
        
        if (status.category == PNDisconnectedCategory) {
            
            /**
             This is the expected category for an unsubscribe. This means there was no error in unsubscribing
             from everything.
             */
        }
    }
    else if (status.operation == PNHeartbeatOperation) {
        
        /**
         Heartbeat operations can in fact have errors, so it is important to check first for an error.
         For more information on how to configure heartbeat notifications through the status
         PNObjectEventListener callback, consult http://www.pubnub.com/docs/ios-objective-c/api-reference-sdk-v4#configuration_basic_usage
         */
        
        if (!status.isError) { /* Heartbeat operation was successful. */ }
        else { /* There was an error with the heartbeat operation, handle here. */ }
    }
    
    // General status checks:
    if (status.category == PNUnexpectedDisconnectCategory) {
        
        // This event happens when radio / connectivity is lost
        CLS_LOG(@"Pubnub client was disconnected");
    }
    else if (status.category == PNConnectedCategory) {
        
        /**
         Connect event. You can do stuff like publish, and know you'll get it.
         Or just use the connected event to confirm you are subscribed for
         UI / internal notifications, etc
         */
        
        CLS_LOG(@"Pubnub client connected successfully");
        [self enablePushOnChannels:self.channelsToSubscribe];
        
    }
    else if (status.category == PNReconnectedCategory) {
        
        /**
         Happens as part of our regular operation. This event happens when
         radio / connectivity is lost, then regained.
         */
        CLS_LOG(@"Pubnub client reconnected");
        
    }
    else if (status.category == PNDecryptionErrorCategory) {
        
        /**
         Handle messsage decryption error. Probably client configured to
         encrypt messages and on live data feed it received plain text.
         */
        CLS_LOG(@"Pubnub client encountered a decryption error: %@", status.description);
    }
}

- (void) client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    CLS_LOG(@"Message received: %@", message);
}

- (NSString *)monitoringChannel {
    return @"monitoring_roger@yamm.ca";
}

- (void)enablePushOnChannels:(NSArray *)channels {
    // Enable APNS on the specific channel with deviceToken
    
    __weak id weakSelf = self;
    
    [pubNub addPushNotificationsOnChannels:channels withDevicePushToken:deviceToken andCompletion:^(PNAcknowledgmentStatus * _Nonnull status) {
        CLS_LOG(@"BLOCK: enablePushNotificationsOnChannel channels: %@ , Error %@",channels,status.errorData.description);
        if (!status.isError) {
            [AppDelegate fireDebugLocalNotification:[NSString stringWithFormat:@"Connected to %@", channels]];
            [[YikesEngine sharedInstance] logMessage:[NSString stringWithFormat:@"[PN] Enabled Push Notifications on channels %@", channels]];
            // All done - reset the PubNub Subscribe Retries count:
            _pubNubSubscribeRetries = 0;
        }
        else {
            NSString *message = [NSString stringWithFormat:@"[PN] Error enabling push notification for %@", channels];
            [AppDelegate fireDebugLocalNotification:message];
            [[YikesEngine sharedInstance] logMessage:message];
            [weakSelf retryPubNubSubscription];
        }
    }];
}

- (void)stopPubNubWithCompletion:(void(^)())completion {
    
    if (!deviceToken) {
        DLog(@"Can't stop PubNub w/o the device token!");
        return;
    }
    
    [self unsubscribeFromAllPubNubChannelsCompletion:^(NSError *error) {
        if (error) {
            CLS_LOG(@"Error unsubscribing: %@", error);
        }
        else {
            
            [pubNub removeAllPushNotificationsFromDeviceWithPushToken:deviceToken andCompletion:^(PNAcknowledgmentStatus * _Nonnull status) {
                if (!status.isError) {
                    CLS_LOG(@"");
                }
                else {
                    CLS_LOG(@"");
                }
             }];
            [pubNub unsubscribeFromChannels:self.channelsToSubscribe withPresence:NO];
        }
    }];
}

- (void)unsubscribeFromAllPubNubChannelsCompletion:(void(^)(NSError *error))completion {
    
    PNConfiguration *myConfig = [self pubNubConfig];
    
    if (myConfig) {
        if (pubNub && deviceToken) {
            NSArray *allChannels = [pubNub channels];
            if (allChannels.count) {
                [pubNub removeAllPushNotificationsFromDeviceWithPushToken:deviceToken andCompletion:^(PNAcknowledgmentStatus * _Nonnull status) {
                    if (!status.isError) {
                        CLS_LOG(@"Successfully removed all push notifications from device");
                        if (completion) completion(nil);
                    }
                    else {
                        CLS_LOG(@"Error: Failed to removeAllPushNotifications from device");
                        if (completion) completion([NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                                                       code:-999 userInfo:@{
                                                                                            NSLocalizedDescriptionKey: status.errorData
                                                                                            }]);
                    }
                }];
            }
            else {
                CLS_LOG(@"No channels to remove push notifications from.");
                if (completion) completion(nil);
            }
        }
        else {
            NSString *errorMessage = @"Error: No pubNub reference or deviceToken - cannot unsubscribe";
            CLS_LOG("%@", errorMessage);
            if (completion) completion([NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                                           code:-1
                                                       userInfo:@{
                                                                  NSLocalizedDescriptionKey: errorMessage
                                                                  }
                                        ]);
        }
    }
    else {
        CLS_LOG(@"Error: No PubNub configuration found - cannot unsubscribeFromAllPubNubChannels");
    }
}

- (void)sendPushNotificationWithAlert:(NSString *)alert {
    NSString *monitoringChannel = [self monitoringChannel];
    [pubNub publish:alert toChannel:monitoringChannel withCompletion:^(PNPublishStatus * _Nonnull status) {
        if (!status.isError) {
            DLog(@"Push Success: %@", alert);
        }
        else {
            DLog(@"Push Failed");
        }
    }];
}


#pragma mark - App Infos

+ (NSString *)fullVersionString {
    NSString *versionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    NSString *fullVersionString;
    
    fullVersionString = [NSString stringWithFormat:@"%@ (%@)", versionString, buildString];
    
#ifdef DEBUG
    fullVersionString = [fullVersionString stringByAppendingString:@" d"];
#endif
    
    return fullVersionString;
}


#pragma mark - screen size

-(BOOL)isIPhone6plus {
    if (([[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]) && ([UIScreen mainScreen].nativeScale > 2.1)) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isIPhone4size {
   
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;

    if (screenHeight < 500) {
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL)isIPhone5size {
   
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;

    if (screenHeight > 500 && screenHeight < 600) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void)testSizeMethods {
    
    NSLog(@"Is 6Plus? %@", [self isIPhone6plus]? @"YES" : @"NO");
    NSLog(@"Is 4S? %@", [self isIPhone4size]? @"YES" : @"NO");
    NSLog(@"Is 5? %@", [self isIPhone5size]? @"YES" : @"NO");
    
    
}

- (void)setFabricUserInfo {
    YKSUserInfo *userInfo = [[YikesEngine sharedEngine] userInfo];
    if (userInfo) {
        [CrashlyticsKit setUserEmail:userInfo.email];
        NSString *userName = [NSString stringWithFormat:@"%@ %@", userInfo.firstName, userInfo.lastName];
        [CrashlyticsKit setUserName:userName];
        [CrashlyticsKit setUserIdentifier:userInfo.deviceId];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


@end
