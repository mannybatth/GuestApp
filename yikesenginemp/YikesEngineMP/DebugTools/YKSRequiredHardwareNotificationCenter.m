//
//  YKSDebugNotificationCenter.m
//  yikes
//
//  Created by royksopp on 2015-05-13.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSRequiredHardwareNotificationCenter.h"
#import "YBLEManager.h"
#import "YKSServicesManager.h"

@import YikesSharedModel;

NSString *const YKS_REQUIRED_HARDWARE_NO_BLUETOOTH = @"Bluetooth is OFF";
NSString *const YKS_REQUIRED_HARDWARE_NO_INTERNET = @"No internet connection";
NSString *const YKS_REQUIRED_HARDWARE_NO_LOCATION_SERVICE = @"Location service is OFF";
NSString *const YKS_REQUIRED_HARDWARE_NO_BACKGR_APP_REFRESH = @"Background app refresh is OFF";
NSString *const YKS_REQUIRED_HARDWARE_NO_PUSH_NOTIFICATIONS = @"Push Notifications are OFF";


@interface YKSRequiredHardwareNotificationCenter ()

@property (nonatomic, strong) NSMutableSet *missingRequiredHardwareEnumsSet;
@property (nonatomic, strong) NSMutableSet *missingRequiredHardwareMessagesSet;
//@property (nonatomic, strong) NSArray *requiredHardwareTextMessagesArray;

@end

@implementation YKSRequiredHardwareNotificationCenter

+ (YKSRequiredHardwareNotificationCenter *)sharedCenter {
    static YKSRequiredHardwareNotificationCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (id) init {
    
    self = [super init];
    if (self) {
        [self initializeNotificationsArray];
        [self readRequiredHardwareState];
    }
    
    return self;
}


- (void)readRequiredHardwareState {
    
    [[YKSServicesManager sharedManager] missingServices:^(NSSet *missingServices) {
        [self callFromEngineIsMissingServices:missingServices];
    }];
}


- (void)initializeNotificationsArray {
    self.missingRequiredHardwareEnumsSet = [NSMutableSet set];
    self.missingRequiredHardwareMessagesSet = [NSMutableSet set];
}


- (void)callFromEngineIsMissingServices:(NSSet *)missingServices {
    
    self.missingRequiredHardwareEnumsSet = [NSMutableSet set];
    self.missingRequiredHardwareMessagesSet = [NSMutableSet set];
    
    for (NSNumber *missingService in missingServices) {
        
        NSInteger missServInt = [missingService integerValue];
        
        switch (missServInt) {
            case kYKSUnknownService:
                // Ignored
                break;
                
            case kYKSBluetoothService:
                [self.missingRequiredHardwareEnumsSet addObject:@(kYKSBluetoothService)];
                [self.missingRequiredHardwareMessagesSet addObject:YKS_REQUIRED_HARDWARE_NO_BLUETOOTH];
                break;
                
            case kYKSLocationService:
                [self.missingRequiredHardwareEnumsSet addObject:@(kYKSLocationService)];
                [self.missingRequiredHardwareMessagesSet addObject:YKS_REQUIRED_HARDWARE_NO_LOCATION_SERVICE];
                break;
                
            case kYKSInternetConnectionService:
                [self.missingRequiredHardwareEnumsSet addObject:@(kYKSInternetConnectionService)];
                [self.missingRequiredHardwareMessagesSet addObject:YKS_REQUIRED_HARDWARE_NO_INTERNET];
                break;
                
            case kYKSPushNotificationService:
                [self.missingRequiredHardwareEnumsSet addObject:@(kYKSPushNotificationService)];
                [self.missingRequiredHardwareMessagesSet addObject:YKS_REQUIRED_HARDWARE_NO_PUSH_NOTIFICATIONS];
                break;
                
            case kYKSBackgroundAppRefreshService:
                [self.missingRequiredHardwareEnumsSet addObject:@(kYKSBackgroundAppRefreshService)];
                [self.missingRequiredHardwareMessagesSet addObject:YKS_REQUIRED_HARDWARE_NO_BACKGR_APP_REFRESH];
                break;
                
            default:
                break;
        }
    }
    
    [self createMessagesArrayAndCallDelegate];
}


#pragma mark - private methods

- (void)createMessagesArrayAndCallDelegate {
    
    NSSet *requiredHardwareEnumsSetCopy = [NSSet setWithSet:self.missingRequiredHardwareEnumsSet];
    
    if (self.requiredHardwareDelegate
        && [self.requiredHardwareDelegate respondsToSelector:@selector(requiredHardwareUpdate:)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.requiredHardwareDelegate requiredHardwareUpdate:[requiredHardwareEnumsSetCopy count]];
        });
    }
    
    
    if (self.requiredHardwareMessagesAvailableDelegate
        && [self.requiredHardwareMessagesAvailableDelegate respondsToSelector:@selector(requiredHardwareNewMessagesAvailable:)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.requiredHardwareMessagesAvailableDelegate requiredHardwareNewMessagesAvailable:requiredHardwareEnumsSetCopy];
        });
    }
}

#pragma mark -

- (NSArray *)requireHardwareCurrentMessages {
    return [self.missingRequiredHardwareMessagesSet allObjects];
}




@end
