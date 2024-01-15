//
//  YKSServicesManager.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-05-25.
//
//

#import "YKSServicesManager.h"
#import "AFNetworkReachabilityManager.h"
#import "YBLEManager.h"
#import <CoreLocation/CoreLocation.h> //until YKSLocationManager is created, just use this
#import "YKSLogger.h"

@import YikesSharedModel;

@interface YKSServicesManager() <CBCentralManagerDelegate>

@property (nonatomic) BOOL isInternetConnectionMissing;

@property (nonatomic, strong) CBCentralManager * throwawayCentralManager;
@property (nonatomic, copy) void (^bluetoothOnCompletionBlock)(BOOL);

@end

@implementation YKSServicesManager

+ (instancetype)sharedManager {
    
    static YKSServicesManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSServicesManager alloc] init];
    });
    
    return _sharedManager;
}


- (instancetype)init {
    
    self = [super init];
    if (self) {
       
        [self setNotifyBlockForReachability];
        [self registerForBackgroundRefreshStatusChangeNotifications];
        
    }
    
    return self;
    
}

#pragma mark - Reachability (Internet)

- (void)setNotifyBlockForReachability {
  
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        [self checkForMissingServices];
    }];
    
    
}

- (BOOL)isReachable {

    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusUnknown) {
        return [[AFNetworkReachabilityManager sharedManager] isReachable];
    }
    return YES;
    
}

#pragma mark - Bluetooth

- (void)isBluetoothOn:(void(^)(BOOL isOn))completion {
    
    self.bluetoothOnCompletionBlock = completion;
    
    //we want to avoid having to start the BLEE, so the enable dialogs dont pop up before walkthrough
    if (!self.throwawayCentralManager) {
        self.throwawayCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                            queue:nil
                                                                          options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    BOOL isOn = central.state == CBCentralManagerStatePoweredOn || central.state == CBCentralManagerStateResetting;
    
    if (self.bluetoothOnCompletionBlock) {
        self.bluetoothOnCompletionBlock(isOn);
        self.bluetoothOnCompletionBlock = nil;
    }
    
    self.throwawayCentralManager = nil;
}

//Called directly by YBLEManager
- (void)handleBluetoothStateChanged {
   
    [self checkForMissingServices];
    
}


#pragma mark - Location

- (BOOL)isBeaconRangingEnabled {
    
    return [CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied &&
                                                           [CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined);
    
}

- (void)handleLocationNotAuthorized {
   
    [self checkForMissingServices];
    
}


#pragma mark - Push Notifications

- (BOOL)arePushNotificationsEnabled {
   
    UIApplication *application = [UIApplication sharedApplication];
    
    BOOL enabled = NO;

    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (notificationSettings && (notificationSettings.types & UIUserNotificationTypeAlert)) {
            enabled = YES;
        }
        
    }
    
    return enabled;
}


#pragma mark - Background Refresh

- (BOOL)isBackgroundRefreshEnabled {
   
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable) {
        return YES;
    } else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied) {
        return NO;
    } else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted) {
        //Eg: parental restrictions
        return NO;
    }
    
    return NO;
    
}

- (void)registerForBackgroundRefreshStatusChangeNotifications {
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBackgroundRefreshStatusChanged) name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
    
}

//Note: on Elliot's iPhone 6  w iOS 8.3 (12F70) - this always returns UIBackgroundRefreshStatusAvailable, even when setting the switch
//in the settings app to Off.
- (void)handleBackgroundRefreshStatusChanged {
    [self checkForMissingServices];
}

#pragma mark - All Services

- (void)missingServices:(void(^)(NSSet *))completion {
    
    NSMutableSet * missingServices = [NSMutableSet set];
    
    if (![self isReachable] || self.isInternetConnectionMissing) {
        [missingServices addObject:@(kYKSInternetConnectionService)];
    }
    
    if (![self isBeaconRangingEnabled]) {
        [missingServices addObject:@(kYKSLocationService)];
    }
    
    if (![self arePushNotificationsEnabled]) {
        [missingServices addObject:@(kYKSPushNotificationService)];
    }
    
    if (![self isBackgroundRefreshEnabled]) {
        [missingServices addObject:@(kYKSBackgroundAppRefreshService)];
    }
    
    [self isBluetoothOn:^(BOOL isOn) {
        
        if (!isOn) {
            [missingServices addObject:@(kYKSBluetoothService)];
        }
        
        completion(missingServices);
    }];
    
}

//- (NSString *)missingServicesDescription {
//    
//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
//   
//    NSSet * missingServices = [self missingServices];
//   
//    NSMutableString * missingMessage = [NSMutableString string];
//
//    if (missingServices.count == 0) {
//        [missingMessage appendString:@"No services are missing"];
//    } else {
//        [missingMessage appendString:@"The following services are missing\n"];
//    }
//    
//    //NB: same order as enum
//    /*
//     kYKSUnknownService,
//     kYKSBluetoothService,
//     kYKSLocationService,
//     kYKSInternetConnectionService,
//     kYKSPushNotificationService,
//     kYKSBackgroundAppRefreshService
//     */
//
//    NSArray * messages = @[@"Unknown service",
//                           @"Bluetooth is disabled",
//                           @"Location services is disabled",
//                           @"No Internet connection",
//                           @"Push notifications are disabled",
//                           @"Background Refresh is disabled"];
//   
//    for (NSNumber * missingService in missingServices) {
//        
//        NSString * serviceMessage = messages[missingService.intValue];
//        [missingMessage appendFormat:@"%@\n", serviceMessage];
//    }
//  
//    [missingMessage appendFormat:@"(%f sec)", [NSDate timeIntervalSinceReferenceDate] - start]; //just to get an idea of how long [self missingServices] takes
//    
//    return [NSString stringWithString:missingMessage];
//    
//}

#pragma mark - Delegate related methods

- (void)checkForMissingServicesWithOperationError:(NSError *)error {
    
    if (error.code == kCFURLErrorNotConnectedToInternet) {
        
        self.isInternetConnectionMissing = YES;
        [self checkForMissingServices];
        
    }
    
}

- (void)checkForMissingServicesOnlyIfInternetWasNotFound {
    
    if (self.isInternetConnectionMissing) {
        
        self.isInternetConnectionMissing = NO;
        [self checkForMissingServices];
        
    }
}

- (void)checkForMissingServices {
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(engineIsMissingServices:)]) {
        
        [self missingServices:^(NSSet *missingServices) {
            [self.delegate engineIsMissingServices:missingServices];
        }];
        
    }
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationBackgroundRefreshStatusDidChangeNotification object:nil];
}

@end
