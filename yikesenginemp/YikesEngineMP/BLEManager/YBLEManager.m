
//
//  YBLEManager.m
//  yadminlab
//
//  Created by Elliot on 2/6/2014.
//  Copyright (c) 2014 Yamm Software. All rights reserved.
//

#import "YBLEManager.h"
#import "YikesBLEConstants.h"
#import "YMotionManager.h"
#import "ConnectionManager.h"
#import "YKSSessionManager.h"
#import "YKSFileLogger.h"
#import "YKSServicesManager.h"
#import "YKSLocationManager.h"
#import "YKSLogger.h"
#import "YKSUser.h"
#import "YKSStay.h"
#import "YikesEngineMP.h"
#import "YKSBinaryHelper.h"
#import "YKSDeviceHelper.h"
#import "YKSErrorReporter.h"

@import YikesSharedModel;

#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>

@interface YBLEManager () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager * centralManager;

@property (nonatomic, strong) ConnectionManager *connectionManager;


// The stay - required for stay token and stay validity:
@property (nonatomic, strong) UserStay *userStay;

@property (nonatomic, strong) CBPeripheral * currentPeripheral; //used for when we don't yet know which peripheral it isa

// New method, store the current stay so that we know if we should disconnect when it's updated
// This should not be used for the stay info, only checked against when a new one is downloaded
@property (nonatomic, strong) YKSStay * previouslyDownloadedStay;

@property (nonatomic, strong) CompletedWithError callbackWithError;

@property (assign) BOOL alreadyShowedStationaryLog;

//Dictionaries used to store RSSI readings from yMAN and Elevator
//key: peripheral (CBPeripheral *)
//value: {"RSSI":RSSI value (NSNumber *), this is the TOTAL rssi to be divided by count
//        "count":number of readings (NSNumber *)}
@property (nonatomic, strong) NSMutableDictionary * yManRSSIReadings;
@property (nonatomic, strong) NSMutableDictionary * elevatorRSSIReadings;

//YLink related
@property (nonatomic, strong) CBPeripheral * yLink;
@property (nonatomic, strong) CBService * elevatorYLinkService;

@property (nonatomic, strong) CBUUID * yLinkAdvertisingServiceUUID;
@property (nonatomic, strong) CBUUID * elevatoryLinkAdvertisingServiceUUID;

@property (nonatomic, strong) CBUUID * yLinkReadCharacteristicUUID;
@property (nonatomic, strong) CBUUID * yLinkWriteCharacteristicUUID;

@property (nonatomic, strong) NSSet *previousUUIDScanList;

#pragma mark - BLE Engine state

/**
 * Allows to disconnect quietly on logout and stop the BLE engine
 * It is reset when calling beginScanningForYikesHardware on login
 */
@property (nonatomic, assign) BOOL isResettingBLEEngine;

@property (nonatomic, assign) BOOL hasRequestedStayInfo;
@property (nonatomic, strong) NSDate *hasRequestedStayInfoOn;

@property (nonatomic, assign) BOOL overridden;
@property (nonatomic, assign) BOOL elevatorOverridden;

#pragma mark - Elevator state
@property (nonatomic, assign) BOOL elevatorConnectionAttemptFailed;

#pragma mark - Error and Trials

@property (nonatomic, assign) NSInteger numberOfElevatorConnectTrials;

//GCD Queue
@property (nonatomic, strong) dispatch_queue_t centralQueue;

#pragma mark - Timers

@property (nonatomic, strong) MSWeakTimer * elevatorYLinkStatusTimer;
@property (nonatomic, strong) MSWeakTimer * elevatorConnectTimer;

@property (nonatomic, strong) MSWeakTimer *debugInfoTimer;

@property (nonatomic, strong) NSDateFormatter *debugDateFormatter;

@property (nonatomic, strong) MSWeakTimer * repeatingScanTimer;

@property (nonatomic, strong) MSWeakTimer * yLinkDisconnectTimer;

@property (nonatomic, strong) MSWeakTimer *batteryMonitoringTimer;

#pragma mark -
#pragma mark - Elevators identification

@property (nonatomic, strong) NSMutableArray* elevatorsIdentifications;

#pragma mark -
-(void)sendInfoToDelegate:(NSString *)message;

- (NSString *)macAddressFromAdvUUID:(NSUUID *)advUUID;

@end

@implementation YBLEManager

@synthesize overridden, elevatorOverridden;

#pragma mark Init-related methods

+ (YBLEManager *)sharedManager {
    static YBLEManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
#ifdef DEBUG
        NSLog(@"SINGLETON INIT");
#endif
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


+ (YBLEManager *)sharedManagerWithUserStay:(UserStay *)stay {
    YBLEManager *_sharedInstance = [self sharedManager];
    if (_sharedInstance && stay) {
        [_sharedInstance setUserStayTo:stay];
        DLog(@"Stay from app is %@", stay);
        DLog(@"User stay copied from app is %@", _sharedInstance.userStay);
        DLog(@"");
    }
    else if (_sharedInstance) {
        [_sharedInstance setUserStayTo:nil];
    }
    return _sharedInstance;
}

+ (NSDictionary *)plRoomAuth_Modes_Dictionary {
    static NSDictionary *dic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = @{
                 @(PLRoomAuth_Mode_Normal): @"Normal",
                 @(PLRoomAuth_Mode_BadAuth_13bytes_Random_TrackID): @"13 bytes Random TrackID",
                 @(PLRoomAuth_Mode_BadAuth_13bytes_Random_StayToken): @"13 bytes Random StayToken",
                 @(PLRoomAuth_Mode_BadAuth_13bytes_Random_Both): @"13 bytes Random Both",
                 @(PLRoomAuth_Mode_BadAuth_13bytes_All0Message): @"13 bytes All-0 Message",
                 @(PLRoomAuth_Mode_BadAuth_21bytes_Random_TrackID):@"21 bytes Random TrackID",
                 @(PLRoomAuth_Mode_BadAuth_21bytes_Random_StayToken):@"21 bytes Random StayToken",
                 @(PLRoomAuth_Mode_BadAuth_21bytes_Random_Both):@"21 bytes Random Both",
                 @(PLRoomAuth_Mode_BadAuth_21bytes_All0Message):@"21 bytes All-0 Message",
                 @(PLRoomAuth_Mode_BadAuth_21bytes_AllRandomMessage): @"21 bytes All Random Message"
                 };
    });
    return dic;
}

-(NSString *)bleEngineVersion {
    
    NSString * version = [NSString stringWithFormat:@"%u", BLE_ENGINE_VERSION];
    return version;
    
}

-(BOOL)isBluetoothEnabled {
    return self.centralManager.state == CBCentralManagerStatePoweredOn;
}


#pragma mark - Custom Setters

- (void)logScanList {
    NSString * scanDevices = [NSString stringWithFormat:@"Scanning for %@", self.previousUUIDScanList];
    
    //Not an error
    [[YKSLogger sharedLogger] logMessage:scanDevices withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeBLE];
}

- (void)setInternalBleEngineState:(YKSBLEEngineState)internalBleEngineState {
    _internalBleEngineState = internalBleEngineState;
}


#pragma mark - delegate convenience methods

-(void)updateProximityStateDelegateWithState:(ProximityState)newState {
    if (self.proximityStateDelegate) {
        [self.proximityStateDelegate yikesLocationStateChanged:newState];
    }
}


#pragma mark - Debugger Settings

- (void)setScanForElevator:(BOOL)scanForElevator {
    if (scanForElevator) {
        if ([self.debugDelegate respondsToSelector:@selector(elevatorYLinkUpdate:)]) {
            [self.debugDelegate elevatorYLinkUpdate:@"Enabled"];
        }
    }
    else {
        if (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state != CBPeripheralStateDisconnected) {
            [self.centralManager cancelPeripheralConnection:self.connectionManager.elevatorYLink];
        }
        if ([self.debugDelegate respondsToSelector:@selector(elevatorYLinkUpdate:)]) {
            [self.debugDelegate elevatorYLinkUpdate:@"Disabled"];
        }
    }
    
    _scanForElevator = scanForElevator;
}


#pragma mark 0.2.0 MultiAccess / Primary yMAN

-(NSInteger)timeBetweenScans {
   
    if ([[YMotionManager sharedManager] isStationary]) {
        return SCAN_TIMER_INTERVAL_STATIONARY;
    } else {
        return SCAN_TIMER_INTERVAL;
    }
    
    
}

//Repeated calls should do nothing if the timer is running. To restart, call stop and then start
-(void)startScanTimer {
  
    if (!self.repeatingScanTimer) {
        self.repeatingScanTimer = [MSWeakTimer scheduledTimerWithTimeInterval:[self timeBetweenScans] target:self selector:@selector(scanTimerTimeout) userInfo:nil repeats:NO dispatchQueue:self.centralQueue];
    }
    
}

-(void)stopScanTimer {
    
    if (self.repeatingScanTimer) {
        [self.repeatingScanTimer invalidate];
    }
    
    self.repeatingScanTimer = nil;
    
}

-(void)scanTimerTimeout {
    
    dispatch_async(self.centralQueue, ^{
        [self scanForNecessaryDevices];
    });
    [self stopScanTimer];
    [self startScanTimer];
    
}

-(void)scanForNecessaryDevices {
    
    [self.connectionManager cleanUpGuestAuths];
    
    if ([YikesEngineMP sharedEngine].engineState == kYKSEngineStatePaused) {
    
        [[YKSLogger sharedLogger] logMessage:@"Engine is paused, not scanning" withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeBLE];
        
        return;
        
    }
    
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    DLog(@"All yLinks: %@", [self.connectionManager allYLinks]);
    
    DLog(@"Disconnected yLinks: %@", [self.connectionManager disconnectedYLinksWithNoActiveGuestAuths]);
    
    //Do not scan if we are not in the beacon region AND location services are OFF
    if (![[YKSLocationManager sharedManager] isInsideYikesRegion]) {// if we wantd to allow room access w/o proximity...  && [self checkLocationServicesON]) {
        
        if (self.debugDelegate) {
            [self.debugDelegate foundYMEN:@"Outside"];
            [self.debugDelegate informationUpdated:@""];
            [self.debugDelegate yLinkUpdate:@""];
            [self.debugDelegate elevatorYLinkUpdate:@""];
        }
        
        [[YKSLogger sharedLogger] logMessage:@"Outside of yikes iBeacon region - Stopping the BLE Engine"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        // no need to scan while outside:
        [self stopAllScanActivity];
        
        //TODO: Bad stuff!
        return;
    }
    
    // We passed the early returns, BLE Scanning start confirmed:
    self.internalBleEngineState = kYKSBLEEngineStateOn;
   
    //Connects to closest elevator from previous scan cycle
    [self connectToClosestElevator];
    
    NSMutableSet * uuids = [NSMutableSet set];
    
    //Add elevator
    if (![[YMotionManager sharedManager] isStationary]) {
        if (!self.connectionManager.elevatorYLink || (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state == CBPeripheralStateDisconnected) ) {
            [uuids addObject:self.elevatoryLinkAdvertisingServiceUUID];
            [self.debugDelegate scanningForDevice:kDeviceElevatorYLink];
        }
        else if (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state == CBPeripheralStateConnecting) {
            [self.debugDelegate elevatorYLinkUpdate:@"Connecting..."];
        }
        else if ([self isConnectedToElevator]) {
            [self.debugDelegate connectedToDevice:kDeviceElevatorYLink];
        }
    }
    
    //Add primary ymen
    NSArray *primaryYMENUUIDs = [self.connectionManager advertisingUUIDsToScanForPrimaryYMEN];
    [uuids addObjectsFromArray:primaryYMENUUIDs];
    
    if (primaryYMENUUIDs && primaryYMENUUIDs.count > 0) {
        
        
        //Reporter, Old Console, New Console calls:
        
        //From old console, still used for elevator TODO: get rid of this
        YMan *yMan = [self.connectionManager yManFromAdvertisingUUID:primaryYMENUUIDs.firstObject];
        if (![self.connectionManager areThereAnyActiveGuestAuthsForYMan:yMan]) {
            [self.debugDelegate scanningForDevice:kDeviceYMAN];
        }
        else {
            [self.debugDelegate informationUpdated:@""];
        }
        
        NSArray * macAddresses = [self.connectionManager macAddressesForPrimaryYMENToConnect];
        
        //Only tell the reporter to show "started scan" if we actually intend to connect to the yMAN
        if (macAddresses && macAddresses.count > 0) {
            
            [[MultiYManGAuthDispatcher sharedInstance] startedScanForPrimaryYManList:macAddresses];
            
            for (NSData * macAddress in macAddresses) {
                [[MultiYManGAuthDispatcher sharedInstance] startedScanForPYMan:macAddress];
            }
            
        } else {
            
            [[MultiYManGAuthDispatcher sharedInstance] stoppedScanForPrimaryYMan];
        }
        
    }
    else {
        
        [[MultiYManGAuthDispatcher sharedInstance] stoppedScanForPrimaryYMan];
        
        [self.debugDelegate informationUpdated:@""];
    }
    
    
    
    
    //Add yLinks
    NSArray *yLinks = [self.connectionManager yLinkAdvUUIDsToScanFor:YES];
    
    [uuids addObjectsFromArray:yLinks];
    
    if (yLinks && yLinks.count) {
        [self.debugDelegate scanningForDevice:kDeviceYLink];
    }
    else {
        NSArray *connectedYLinks = [self.connectionManager connectedYLinks];
        if (connectedYLinks && connectedYLinks.count) {
            [self.debugDelegate connectedToDevice:kDeviceYLink];
        }
        else {
            [self.debugDelegate yLinkUpdate:@""];
        }
    }
    
    NSDictionary *scanningOptions = @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO };
    
    if (uuids.count > 0) {
        
        // only output if the list was updated since last output:
        if (!self.previousUUIDScanList || ![uuids isEqualToSet:self.previousUUIDScanList]) {
            
            NSString * scanDevices = [NSString stringWithFormat:@"Scan list:\n%@", uuids];
            
            [[YKSLogger sharedLogger] logMessage:scanDevices
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeBLE];
            
            // print yMen that we are not connecting with
            NSMutableArray *notConnectingList = [NSMutableArray arrayWithCapacity:primaryYMENUUIDs.count];
            for (CBUUID *cbuuid in primaryYMENUUIDs) {
                YMan *yMan = [self.connectionManager yManFromAdvertisingUUID:cbuuid];
                if (yMan && ![self.connectionManager shouldConnectToYMan:yMan]) {
                    [notConnectingList addObject:cbuuid];
                }
            }
            
            NSString * notConnectingDevices = [NSString stringWithFormat:@"Not connecting with:\n%@", notConnectingList];
            
            [[YKSLogger sharedLogger] logMessage:notConnectingDevices
                                  withErrorLevel:YKSErrorLevelInfo
                                         andType:YKSLogMessageTypeBLE];
        }
        
        self.previousUUIDScanList = [uuids copy];
        
        [self.centralManager stopScan];
        
        [self.centralManager scanForPeripheralsWithServices:uuids.allObjects options:scanningOptions];
    }
    else {
        
        [self.centralManager stopScan];
    }
    
}

#pragma mark - BLE Stay

- (void)requestStayInfoUpdate {
    if (self.dataDelegate) {
        
        // Avoid requesting stay infos in parallel
        // The time interval is to ensure the request didn't fail and the stay is never refreshed
        
        BOOL isRequestingStayInfo = self.hasRequestedStayInfo;
        
        DLog(@"ti is %@", @([self.hasRequestedStayInfoOn timeIntervalSinceNow]));
        
        BOOL hasRequestedStayInfoRecently = self.hasRequestedStayInfoOn && fabs([self.hasRequestedStayInfoOn timeIntervalSinceNow]) <= 10;
        
        // if the stay has been updated recently, wait for blacklisting to end first and try again:
        if (!isRequestingStayInfo && !hasRequestedStayInfoRecently) {
            
            DLog(@"Requesting Stay Info");
            
            [self.dataDelegate updateStayInfo];
            self.hasRequestedStayInfo = YES;
            self.hasRequestedStayInfoOn = [NSDate date];
        }
        else {
            DLog(@"Already requesting stay info, sent on %@", self.hasRequestedStayInfoOn);
        }
    }
    else {
        [[YKSLogger sharedLogger] logMessage:@"Warning: No Data Delegate for YBLEManager!"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        [[MultiYManGAuthDispatcher sharedInstance] expireAllGuestAuths];
    }
}

/**
 * New way, using new API components
 */
-(void)handleUserInfoUpdatedWithRemovedStays:(NSSet *)removedStays andRemovedAmenities:(NSSet *)removedAmenities withNewRoomAssigned:(BOOL)isNewRoomAssigned {
  
    dispatch_async(self.centralQueue, ^{
    
        NSArray * currentStays = [YKSSessionManager validUserStays];
        
        if (!currentStays || currentStays.count == 0) {
            
            [[YKSLogger sharedLogger] logMessage:@"No valid user stay on update, disconnecting and stopping scan" withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeBLE];
           
            [self stopBLEActivity];
            
            return;
        }
       
        //Assign the yPhoneID from the user
        YKSUser * user = [YKSSessionManager getCurrentUser];
        self.yPhoneID = user.deviceId;
        
        //If there is a new stay or reassigned room, just disconnect + expire all current guest auths to force going
        //back to yMAN
        if (isNewRoomAssigned) {
          
            [self disconnectFromAllYLinksAndExpireGuestAuths];
            
        } else {
        
            NSMutableArray * guestAuthsForDisconnection = [NSMutableArray array];
            
            //If the stay info has changed, disconnect
            if (removedStays) {
                for (YKSStay * stay in removedStays) {
                   
                    [guestAuthsForDisconnection addObjectsFromArray:[self.connectionManager activeGuestAuthsForStay:stay]];
                    
                }
            }
            
            
            if (removedAmenities) {
                for (YKSAmenity * amenity in removedAmenities) {
                    
                    [guestAuthsForDisconnection addObjectsFromArray:[self.connectionManager activeGuestAuthsForAmenity:amenity]];
                    
                }
            }
           
            //Disconnect from guest auths
            for (GuestAuth * guestAuth in guestAuthsForDisconnection) {
               
                [[YBLEManager sharedManager] disconnectFromyLinkWithTrackID:guestAuth.trackID];
                [guestAuth setExpired];
                
            }
            
            //Go through active guest auths, make sure they point to the new stay
            NSArray * activeGuestAuths = [self.connectionManager activeGuestAuths];
           
            for (GuestAuth * guestAuth in activeGuestAuths) {
              
                //For each guest auth, see if the current stay matches a new one
                
                id stayOrAmenity = [YKSSessionManager stayOrAmenityForRoomNumber:guestAuth.roomNumber];
                
                if ([stayOrAmenity class] == [YKSStay class]) {
                    
                    guestAuth.stay = (YKSStay *)stayOrAmenity;
                    
                } else if ([stayOrAmenity class] == [YKSAmenity class]) {
                   
                    guestAuth.amenityDoor = (YKSAmenity *)stayOrAmenity;
                    
                }
                
            }
            
        }
        [self.connectionManager updatePrimaryYMen:[YKSSessionManager allPrimaryYMen]];
        
        //Here for transition, should be re-examined + possibly deleted
        self.isResettingBLEEngine = NO;

        [self startLoggingBatteryLevel];
        [self beginScanningForYikesHardware];
        
    }); //end dispatch_async
}

/**
 * Old way, using legacy API components
 */
- (void)setUserStayTo:(id)theStay {
    
    self.hasRequestedStayInfo = NO;
    
    if (theStay) {
        UserStay *s = [[UserStay alloc] init];
        s.is_active = ((UserStay *)theStay).is_active;
        s.at_hotel_flag = ((UserStay *)theStay).at_hotel_flag;
        s.stay_status_code = ((UserStay *)theStay).stay_status_code;
        s.arrival_date = ((UserStay *)theStay).arrival_date;
        s.depart_date = ((UserStay *)theStay).depart_date;
        s.reservation_number = ((UserStay *)theStay).reservation_number;
        s.room_number = ((UserStay *)theStay).room_number;
       
        //In future, we will need to be more particular about which we disconnect from, but for now just disconnect from all
        if (self.userStay) {
           
            if (![self.userStay.room_number isEqual:s.room_number]) {
        
                [self disconnectFromAllYLinksAndExpireGuestAuths];
                 
            }
            
        }
        
        // this will use the setter from the MO Stay (Extension)
        if ([theStay isKindOfClass:[UserStay class]]) {
            s.primary_ymen = ((UserStay *)theStay).primary_ymen;
        }
        else {
            // legacy code:
        s.primary_ymen = ((UserStay *)theStay).primary_ymen_mac_addresses;
        }
      
        //TODO: should we do this every time?
        //[self.connectionManager expireAllZeroTrackIDGuestAuths];
       
        _userStay = s;
        
        self.isResettingBLEEngine = NO;
        
        [self startLoggingBatteryLevel];
        
        //[self readiBeaconRegionState]; //Why is it called? Can't we just check self.insideYikesRegion?
        
        [self beginScanningForYikesHardware];
    }
    else {
        _userStay = nil;
        [self stopLoggingBatteryLevel];
    }
    
    // update primary yMEN in any case:
    [self setPrimaryYMENFromUserStay];
}

- (void)startLoggingBatteryLevel {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    if (!self.batteryMonitoringTimer) {
        self.batteryMonitoringTimer = [MSWeakTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(logBatteryLevel) userInfo:nil repeats:YES dispatchQueue:self.centralQueue];
        //[self logBatteryLevel];
    }
}

- (void)logBatteryLevel {
    
//    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Battery Level: %3.0f%% at %@", 100 * [[UIDevice currentDevice] batteryLevel], [NSDate date]]
//                                     withErrorLevel:YKSErrorLevelInfo
//                                            andType:YKSLogMessageTypeDevice];
}

- (void)stopLoggingBatteryLevel {
    if (self.batteryMonitoringTimer) {
        [self.batteryMonitoringTimer invalidate];
    }
    self.batteryMonitoringTimer = nil;
}

- (void)setPrimaryYMENFromUserStay {
    NSMutableSet * primaryYMenAddresses = [NSMutableSet set];
    
    for (NSData *address in _userStay.primary_ymen) {
        [primaryYMenAddresses addObject:address];
    }
    
    DLog(@"Primary yMEN will be: %@", _userStay.primary_ymen);
    
    [self.connectionManager updatePrimaryYMen:primaryYMenAddresses];
}

#pragma mark - Init

- (id) init {
    return [self initWithDelegate:nil];
}

- (id) initWithDelegate:(id<YBLEManagerDebugDelegate>)delegate {
    
    self = [super init];
    if (self) {
        
        _internalBleEngineState = kYKSBLEEngineStateOff;
        
        [self initializeCentralManager];
        
        [self initializeLocationManager];
        
        self.debugDelegate= delegate;
        
        self.debugDateFormatter = [[NSDateFormatter alloc] init];
        [self.debugDateFormatter setLocale:[NSLocale currentLocale]];
        [self.debugDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        
        [self initializeLocalProperties];
        
        self.elevatorsIdentifications = [NSMutableArray array];
        
        self.elevatoryLinkAdvertisingServiceUUID = [self combinedUUIDWithTrackIDString:kStaticTrackID];
        
        self.elevatorRSSIThreshold = ELEVATOR_YLINK_THRESHOLD_RSSI;
        
//        [self registerForUserNotifications];
        
        self.connectionManager = [[ConnectionManager alloc] initWithBLEManager:self andQueue:self.centralQueue];
        
#ifdef DEBUG
//        _showDebugNotifications = YES;
#endif
    }
    
    return self;
}

#pragma mark - User

- (BOOL)iOS8_OR_LATER {
    BOOL iOS8 = NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1;
    return iOS8;
}

- (BOOL)iOS7_OR_LATER {
    BOOL iOS7 = NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1;
    return iOS7;
}

#pragma mark - BLE Cycle START

-(void)beginScanningForYikesHardware {
    
    if (![YKSLocationManager sharedManager].isInsideYikesRegion) {
        //TODO: Make sure the engine is set to Paused...:
        
        [[YKSLogger sharedLogger] logMessage:@"Not scanning, not inside MP region."
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeBLE];
        
        return;
    }
    
    if (![YikesEngineMP sharedEngine].shouldStartBLEActivity || ![YikesEngineMP sharedEngine].shouldStartBLEActivity(kYKSEngineArchitectureMultiPath)) {
        
        [[YKSLogger sharedLogger] logMessage:@"Not scanning, not allowed to start BLE activity."
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeBLE];
        
        return;
    }
    
#ifdef YikesEnginePod_YikesPrefix_pch
    
    if (self.centralManager.state == CBCentralManagerStatePoweredOn && (self.userStay || [YKSSessionManager getCurrentUser].currentStay)) {
        [self startScanTimer];
    }
    
#else
    if (self.centralManager.state == CBCentralManagerStatePoweredOn && (self.userStay || [YKSSessionManager getCurrentUser].currentStay)) {
        [self startScanTimer];
    }
#endif
    else {
        [[YKSLogger sharedLogger] logMessage:@"Not starting BLE Engine"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        if (self.centralManager.state == CBCentralManagerStatePoweredOff) {

            [[YKSLogger sharedLogger] logMessage:@"Bluetooth is powered OFF"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
                    }
        else if (!self.userStay && ![YKSSessionManager getCurrentUser].currentStay) {
            [[YKSLogger sharedLogger] logMessage:@"No user stay"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
        }
        
        DLog(@"beginScanningForYikesHardware - NOT doing anything, either no stay or Bluetooth is powered OFF");
        
    [self stopAllScanActivity];
    }
}

#pragma mark -

- (void)initializeCentralManager
{
    self.centralQueue = dispatch_queue_create("co.yikes.centralmanager_queue_serial", DISPATCH_QUEUE_SERIAL);
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:self.centralQueue
                                                             options:
                           @{CBCentralManagerOptionRestoreIdentifierKey:@"centralManager",
                             CBCentralManagerOptionShowPowerAlertKey:@NO
                             }];
    
}

- (void)initializeLocationManager {
   
    [YKSLocationManager sharedManager];
    
}

- (void)checkElevatorYLinkStatus {
    if (self.connectionManager.elevatorYLink.state == CBPeripheralStateConnected) {
        [[YKSLogger sharedLogger] logMessage:@"√√ Still connected to elevator yLink √√"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"√√ Still connected to elevator yLink √√");
    }
    else {
        [[YKSLogger sharedLogger] logMessage:@"## NOT CONNECTED TO ELEVATOR YLINK ##"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"## NOT CONNECTED TO ELEVATOR YLINK ##");
    }
}

-(void)initializeLocalProperties {
    
    self.messageCharacteristicUUID = [CBUUID UUIDWithString:YMAN_CHAR_UUID];
    
    self.yMANServiceUUID  = [CBUUID UUIDWithString:YMAN_SERVICE_UUID];
    
    self.yLinkServiceUUID = [CBUUID UUIDWithString:YLINK_SERVICE_UUID];
    self.yLinkReadCharacteristicUUID = [CBUUID UUIDWithString:YLINK_READ_CHAR_UUID];
    self.yLinkWriteCharacteristicUUID = [CBUUID UUIDWithString:YLINK_WRITE_CHAR_UUID];
    
    self.numberOfElevatorConnectTrials = 0;
    
    overridden = NO;
    elevatorOverridden = NO;
    
    self.yPhoneID = nil;
    
    self.scanForElevator = YES;
    
    self.isResettingBLEEngine = NO;
    
}

- (void)handleLogin {
   
    self.isResettingBLEEngine = NO;
    
    // Always reset this mode:
    self.currentPLRoomAuthMode = PLRoomAuth_Mode_Normal;
    
    [[YKSLocationManager sharedManager] startMonitoringRegion];
    self.centralManager.delegate = self;
}

-(void)handleLogout {
    
    [[YKSLogger sharedLogger] logMessage:@"YBLEManager - handling logout"
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
    // Nil the stay - can't let anyone in without being identified
    self.userStay = nil;
    
    [self initializeLocalProperties];
    
    //TODO: Also stop monitoring for beacon region
    self.isResettingBLEEngine = YES;
    
    [self stopBLEActivity];
    
    [self.connectionManager removeAllGuestAuths];
    [self.connectionManager removeAllPrimaryYMen];
    [self.connectionManager removeAllYLinks];
    
    [[YKSLocationManager sharedManager] stopMonitoringRegion];
    self.centralManager.delegate = nil;
}


#pragma mark - Data related methods

- (BOOL)loggedIn {
    return [YKSSessionManager isSessionActive];
}

#pragma mark State related methods

-(BOOL)shouldSubscribeToHotelApp {
    
    return YES;
    
}

-(NSData *)yPhoneIDFromForm:(NSDictionary *)form {
    
    NSString * yPhoneID = form[@"yPhoneID"];
    if (yPhoneID == nil) {
        [[YKSLogger sharedLogger] logMessage:@"No yPhoneID was found in the dictionary"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"No yPhoneID was found in the dictionary");
        return nil;
    }
    
    if (yPhoneID.length != 12) {
        [[YKSLogger sharedLogger] logMessage:@"The yPhone ID is not the correct number of characters"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"The yPhone ID is not the correct number of characters");
        return nil;
    }
    
    NSData * binaryID = [YKSBinaryHelper binaryFromHexString:yPhoneID];
    
    return binaryID;
}

#pragma mark - YMotionManager handler methods


- (void)handleDeviceBecameStationary {
    
    [self disconnectFromAllPeripheralsAndExpireGuestAuths];
    
    //[self.connectionManager expireAllGuestAuths];
    
    //[self.connectionManager removeAllGuestAuths];
    
    [self updateProximityStateDelegateWithState:kProximityStateInside];
    
    [[MultiYManGAuthDispatcher sharedInstance] expireAllGuestAuths]; //TODO replace with new call
    

}

- (void)handleDeviceBecameActive {
    
    [self beginScanningForYikesHardware];
    
}



#pragma mark - yMAN related methods

-(void)requestAllGuestAuthsFromYMAN:(YMan *)yMan {
    
    if (![self yPhoneID]) {

        [[YKSLogger sharedLogger] logMessage:@"There is no yPhoneID to be written"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        return;
    }
   
    UInt8 header = YMAN_YPHONEID_MSG_ID;
    NSMutableData * message = [NSMutableData dataWithBytes:&header length:1];
    
    NSData * yPhoneID = [YKSBinaryHelper binaryFromHexString:self.yPhoneID];
    [message appendData:yPhoneID];
   
    uint8_t version = BLE_ENGINE_VERSION;
    NSData * versionNumber = [NSData dataWithBytes:&version length:1];
    [message appendData:versionNumber];
    
    [self writeValue:[NSData dataWithData:message] toCharacteristic:yMan.characteristic onPeripheral:yMan.peripheral];
    
    
}


-(void)renewGuestAuthForYLinkAddresses:(NSArray *)macAddresses fromYMAN:(YMan *)yMan {
   
    if (![self yPhoneID]) {

        [[YKSLogger sharedLogger] logMessage:@"There is no yPhoneID to be written"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        return;
    }
    
    if (!macAddresses || macAddresses.count == 0) {

        [[YKSLogger sharedLogger] logMessage:@"RenewGuestAuth: No MAC addresses provided, not renewing"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        return;
    }
    
    if (macAddresses.count > 16) {
        
        [[YKSLogger sharedLogger] logMessage:@"RenewGuestAuth: More than 16 MAC addresses provided, not renewing"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        return;
    }
    

    //Header
    UInt8 header = YMAN_RENEWAUTH_MSG_ID;
    NSMutableData * message = [NSMutableData dataWithBytes:&header length:1];
   
    //yPhone ID
    NSData * yPhoneID = [YKSBinaryHelper binaryFromHexString:self.yPhoneID];
    [message appendData:yPhoneID];
    
    //BLE Engine version
    uint8_t version = BLE_ENGINE_VERSION;
    NSData * versionNumber = [NSData dataWithBytes:&version length:1];
    [message appendData:versionNumber];
   
    //Count (for now 1 always)
    UInt8 count = macAddresses.count;
    [message appendData:[NSData dataWithBytes:&count length:1]];
   
   
    for (NSData * macAddress in macAddresses) {
        
        if ([macAddress length] != 6) {
            
            NSString * message = [NSString
                                  stringWithFormat:@"RenewGuestAuth: Invalid MAC address (%@) passed in, not renewing it", macAddress];

            [[YKSLogger sharedLogger] logMessage:message
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            continue;
        }
        
        [message appendData:macAddress];
        
    }
    
    [self writeValue:[NSData dataWithData:message] toCharacteristic:yMan.characteristic onPeripheral:yMan.peripheral];
    
}

-(void)readStayTokenAndTrackIDFromYMAN:(YMan *)yMan {
    
    if (!yMan.characteristic) {

        [[YKSLogger sharedLogger] logMessage:@"No yMAN characteristic has been discovered."
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        return;
    }
    
    if (![self isReadEnabled:yMan.characteristic.properties]) {

        [[YKSLogger sharedLogger] logMessage:@"The yMAN characteristic does not allow Reads"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        return;
    }
  
    [yMan.peripheral readValueForCharacteristic:yMan.characteristic];
    
}


-(BOOL)isStayTokenMessage:(NSData *)message {
    
    UInt8 * bytes = (UInt8 *)[message bytes];
    if (bytes[0] == YMAN_ROOMAUTH_MSG_ID) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void)resetConditionsToWriteToElevator {
    self.elevatorRSSIReadings = nil;
    self.numberOfElevatorConnectTrials = 0;
}

    
//TODO: make this use immutable dictionaries, get rid of yMAN-related code
-(void)addRSSI:(NSNumber *)RSSI toReadingsDictionaryFromPeripheral:(CBPeripheral *)peripheral {
    
    if ([RSSI isEqual:@127]) {
        //dont add it - 127 means the RSSI value was not accessible for the peripheral at that time, so ignore it
        return;
    }
    
    if (!self.elevatorRSSIReadings) {
        self.elevatorRSSIReadings = [NSMutableDictionary dictionary];
    }
    
    if (![[self.elevatorRSSIReadings allKeys] containsObject:peripheral]) {

        NSMutableDictionary * reading = [@{@"RSSI":RSSI, @"count":@1} mutableCopy];
        
        self.elevatorRSSIReadings[peripheral] = reading;
        
    } else {
        
        NSMutableDictionary * reading = self.elevatorRSSIReadings[peripheral];
        
        int oldCount = [(NSNumber *)reading[@"count"] intValue];
        reading[@"count"] = [NSNumber numberWithInt:oldCount + 1];
        
        int oldRSSI = [(NSNumber *)reading[@"RSSI"] intValue];
        reading[@"RSSI"] = [NSNumber numberWithInt:oldRSSI + [RSSI intValue]];
    }
    
    }
    
-(CBPeripheral *)closestPeripheralFromRSSIReadings:(NSMutableDictionary *)rssiReadings {
    
    //Average RSSI values
    for (NSMutableDictionary * reading in [rssiReadings allValues]) {
        
        if ([reading[@"count"] isEqual:@1]) {
            reading[@"average"] = reading[@"RSSI"];
        } else {
            
            float total = [(NSNumber *)reading[@"RSSI"] floatValue];
            int count = [(NSNumber *)reading[@"count"] intValue];
            
            float average = total / count;
            
            reading[@"average"] = [NSNumber numberWithFloat:average];
            
        }
        
    }
    
//    DLog(@"RSSI found: %@", rssiReadings);
    
    NSArray * results = [rssiReadings keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
        
        NSNumber * rssi1 = ((NSDictionary *)obj1)[@"average"];
        
        NSNumber * rssi2 = ((NSDictionary *)obj2)[@"average"];
        
        return [rssi2 compare:rssi1];
        
        
    }];
    
    return [results firstObject];
    
}

-(void)testClosestYMAN {
    
    NSNumber * RSSI1 = [NSNumber numberWithLong:-33];
    NSNumber * RSSI2 = [NSNumber numberWithLong:-57];
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Compare: %lu", (long)[RSSI1 compare:RSSI2]]
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    //DLog(@"Compare: %d", [RSSI1 compare:RSSI2]);
    
}

-(NSSet *)UUIDSFromAdvertisementData:(NSDictionary *)advertisementData {
   
    NSArray * UUIDs = advertisementData[@"kCBAdvDataServiceUUIDs"];
    NSArray * hashedUUIDs = advertisementData[@"kCBAdvDataHashedServiceUUIDs"]; //when peripheral app is backgrounded, this is what we see
    
    if (UUIDs == nil && hashedUUIDs == nil) {
        return nil;
    }
    
    NSArray * combinedUUIDs;
    
    if (UUIDs == nil) {
        combinedUUIDs = hashedUUIDs;
    } else {
        combinedUUIDs = [UUIDs arrayByAddingObjectsFromArray:hashedUUIDs];
    }
    
    NSSet * uuidSet = [NSSet setWithArray:combinedUUIDs];
    
    return uuidSet;
    
}

-(CBUUID *)firstUUIDFromAdvertisementData:(NSDictionary *)advertisementData {
    
    NSSet * uuidSet = [self UUIDSFromAdvertisementData:advertisementData];
   
    return [[uuidSet allObjects] firstObject];
    
}


#pragma mark -
#pragma mark YLink related methods

-(CBUUID *)combinedUUIDWithTrackID:(NSData *)trackID {
    
    if (trackID == nil || trackID.length != 6.0) {

        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Cannot create combined UUID, invalid stay token: %@", trackID]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"Cannot create combined UUID, invalid stay token: %@", trackID);
        return nil;
    }
    
    NSData * baseUUID = [YKSBinaryHelper binaryFromHexString:YLINK_ADV_SERVICE_BASE_UUID];
    
    NSMutableData * combined = [NSMutableData dataWithData:trackID];
    [combined appendData:baseUUID];
    
    return [CBUUID UUIDWithData:combined];
    
}

-(CBUUID *)combinedUUIDWithTrackIDString:(NSString *)trackIDString {
    
    if (trackIDString == nil || trackIDString.length != 12) {

        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Cannot create combined UUID, invalid stay token: %@", trackIDString]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"Cannot create combined UUID, invalid stay token: %@", trackIDString);
        return nil;
    }
    
    NSData * baseUUID = [YKSBinaryHelper binaryFromHexString:YLINK_ADV_SERVICE_BASE_UUID];
    
    NSData *trackID = [YKSBinaryHelper binaryFromHexString:trackIDString];
    
    NSMutableData * combined = [NSMutableData dataWithData:trackID];
    [combined appendData:baseUUID];
    
    return [CBUUID UUIDWithData:combined];
    
}




-(void)writeRoomAuthToYLink:(CBPeripheral *)yLink  atCharacteristic:(CBCharacteristic *)writeCharacteristic{
   
    GuestAuth * guestAuth = [self.connectionManager guestAuthForYLinkPeripheral:yLink];
   
    //Check that it's a valid roomauth
    if (!guestAuth || (guestAuth.authType != kGuestAuthTypeValid && guestAuth.authType != kGuestAuthTypeWritten)) {
        if (!guestAuth) {

            [[YKSLogger sharedLogger] logMessage:@"Could not retreive guestAuth for given yLink"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            [[MultiYManGAuthDispatcher sharedInstance] didFail:guestAuth.trackID pYman:guestAuth.yMan.macAddress];
        } else if (guestAuth.authType == kGuestAuthTypeExpired) {
            NSString * message = [NSString stringWithFormat:@"BLEManager: WriteRoomAuth: Guest Auth is expired."];

            [[YKSLogger sharedLogger] logMessage:message
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            [[MultiYManGAuthDispatcher sharedInstance] didExpire:guestAuth.trackID pYman:guestAuth.yMan.macAddress];
        } else {
            NSString * message = [NSString stringWithFormat:@"BLEManager: WriteRoomAuth: Invalid RoomAuth for yLink %@, Not writing. AuthType: %lu, trackID: %@\n stay token: %@\n", yLink, (unsigned long)guestAuth.authType, guestAuth.trackID, guestAuth.stayToken];

            [[YKSLogger sharedLogger] logMessage:message
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            [[MultiYManGAuthDispatcher sharedInstance] didFail:guestAuth.trackID pYman:guestAuth.yMan.macAddress];
        }
        
        // Cancel the yLink connection:
        [self.centralManager cancelPeripheralConnection:yLink];
        
        return;
    }
    else if (guestAuth.authType == kGuestAuthTypeWritten) {
        // reset the written status until a write success..
        //[guestAuth setUnWritten];
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Attempting another write to yLink %@\nand trackID %@", guestAuth.yLink.peripheral, guestAuth.trackID]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
    }
    
    //TODO: stop RoomAuth expiration timer
    
    NSData * stayToken = guestAuth.stayToken;
    NSData * trackID = guestAuth.trackID;
    
    if (stayToken == nil || trackID == nil) {
        
        [[YKSLogger sharedLogger] logMessage:@"BLEManager: WriteRoomAuth: Error: Could not write message, stay token and trackID don't both exist."
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];

        [[MultiYManGAuthDispatcher sharedInstance] didFail:guestAuth.trackID pYman:guestAuth.yMan.macAddress];
        
        // Cancel the yLink connection:
        [self.centralManager cancelPeripheralConnection:yLink];
        
        return;
    }
    
    UInt8 header = YLINK_ROOMAUTH_MSG_ID;
    NSMutableData * message = [NSMutableData dataWithBytes:&header length:1];
    
    [message appendData:stayToken];
    [message appendData:trackID];
    
    //Check that we have a reference to the characteristic:
    if (writeCharacteristic == nil) {
        
        [[YKSLogger sharedLogger] logMessage:@"BLEManager: WriteRoomAuth: writeCharacteristic passed in is nil"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        [[MultiYManGAuthDispatcher sharedInstance] didFail:guestAuth.trackID pYman:guestAuth.yMan.macAddress];
        
        // Cancel the yLink connection:
        [self.centralManager cancelPeripheralConnection:yLink];
        return;
    }
    NSString * infoString = [NSString stringWithFormat:@"\nStayToken: %@\nTrackID: %@\n", stayToken, trackID];
    
    [[YKSLogger sharedLogger] logMessage:infoString
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
    
    // See if the PLRoomAuthMode has been modified:
    if (self.currentPLRoomAuthMode > PLRoomAuth_Mode_Normal) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Custom PL_Room_Auth Mode:\n%@", [YBLEManager plRoomAuth_Modes_Dictionary][@(self.currentPLRoomAuthMode)]] withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
        
        NSMutableData *msgID;
        
        // All-0s:
        if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_All0Message ||
            self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_All0Message) {
            
            // Reset the msgID header:
            msgID = [NSMutableData data];
            DLog(@"msgID lenght is %@", @(msgID.length));
            [msgID increaseLengthBy:1];
            
            // set both trackID and Stay Token to 0s:
            NSMutableData *zeros = [NSMutableData data];
            [zeros increaseLengthBy:6];
            stayToken = [zeros copy];
            trackID = [zeros copy];
        }
        
        // random TrackID:
        else if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_Random_TrackID ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_TrackID ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_Random_Both ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_Both ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_AllRandomMessage) {
            // randomize trackID:
            trackID = [YKSBinaryHelper randomDataOfLength:6];
            if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_TrackID) {
                trackID = [YKSBinaryHelper randomDataOfLength:6];
            }
        }
        
        // random Stay Token:
        else if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_Random_StayToken ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_StayToken ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_Random_Both ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_Both ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_AllRandomMessage) {
            // randomize stay token:
            stayToken = [YKSBinaryHelper randomDataOfLength:6];
            if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_Random_StayToken) {
                trackID = [YKSBinaryHelper randomDataOfLength:6];
            }
        }
        
        // random All:
        else {
            // randomize trackID:
            trackID = [YKSBinaryHelper randomDataOfLength:6];
            // randomize stay token:
            stayToken = [YKSBinaryHelper randomDataOfLength:6];
        }
        
        // re-build the message:
        if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_AllRandomMessage) {
            // Also randomize the msgID:
            msgID = [[YKSBinaryHelper randomDataOfLength:1] mutableCopy];
        }
        else if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_13bytes_All0Message ||
                 self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_All0Message) {
            msgID = [NSMutableData data];
            [msgID increaseLengthBy:1];
        }
        else {
            msgID = [NSMutableData dataWithBytes:&header length:1];
        }
        
        message = [NSMutableData dataWithData:msgID];
        [message appendData:stayToken];
        [message appendData:trackID];
        
        // 21 bytes messages are longer by 8 bytes
        if (self.currentPLRoomAuthMode > PLRoomAuth_Mode_BadAuth_13bytes_All0Message) {
            
            NSMutableData *extraBytes;
            if (self.currentPLRoomAuthMode == PLRoomAuth_Mode_BadAuth_21bytes_All0Message) {
                extraBytes = [NSMutableData data];
                [extraBytes increaseLengthBy:8];
            }
            else {
                extraBytes = [[YKSBinaryHelper randomDataOfLength:8] mutableCopy];
            }
            
            [message appendData:extraBytes];
        }
        
        // Writing to a yLink
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Will write data to peripheral %@:\n%@", yLink, message] withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];;
        DLog(@"CurrentPLRoomAuthMode is %@", [YBLEManager plRoomAuth_Modes_Dictionary][@(self.currentPLRoomAuthMode)]);
    }
    else {
        DLog(@"Using the default PL_RoomAuth_Mode");
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"Writing w/ PL_RoomAuth Mode:\n%@", [YBLEManager plRoomAuth_Modes_Dictionary][@([YBLEManager sharedManager].currentPLRoomAuthMode)]];
    [[YKSLogger sharedLogger] logMessage:logMessage withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
    
    [self writeValue:message toCharacteristic:writeCharacteristic onPeripheral:yLink];
}

-(void)writeToElevatorYLink {
    
    if (!self.connectionManager.elevatorYLink) {
        return;
    }
    
    NSData * stayToken = [YKSBinaryHelper binaryFromHexString:kStaticStayToken];
    NSData * trackID = [YKSBinaryHelper binaryFromHexString:kStaticTrackID];
    
    if (stayToken == nil || trackID == nil) {
        DLog(@"Could not write message, stay token and trackID don't both exist.");
        return;
    }
    
    UInt8 header = YLINK_ROOMAUTH_MSG_ID;
    NSMutableData * message = [NSMutableData dataWithBytes:&header length:1];
    
    [message appendData:stayToken];
    [message appendData:trackID];
    
    [self writeValue:message toCharacteristic:self.connectionManager.elevatorWriteCharacteristic onPeripheral:self.connectionManager.elevatorYLink];
    DLog(@"Stay token is %@", stayToken);
    DLog(@"message data is %@", message);
}

- (BOOL)isPeripheralElevatorYLink:(NSDictionary *)advertisementData {
    
    CBUUID * uuid = [self firstUUIDFromAdvertisementData:advertisementData];
    
    
    CBUUID *elevatorUUID = [self combinedUUIDWithTrackIDString:kStaticTrackID];
    
    if ([uuid isEqual:elevatorUUID]) {
        return YES;
    } else {
        return NO;
    }
    
}

- (void)retryElevatorConnection {
    if (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state != CBPeripheralStateConnected) {
        [self startElevatorConnectTimer];
        [self connectToPeripheral:self.connectionManager.elevatorYLink];
        self.numberOfElevatorConnectTrials ++;
    }
}


#pragma mark - Backgrounding stuff

- (void) startScanningInTheBackground {
    __block UIBackgroundTaskIdentifier background_task;
    UIApplication *application = [UIApplication sharedApplication];
    background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
        
        //Clean up code. Tell the system that we are done.
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    
    //To make the code block asynchronous
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //### background task starts
        DLog(@"Running in the background\n");
    });
}


#pragma mark -
#pragma mark Enter/Exit iBeacon Region Handlers

-(void)handleEnteredRegion {

    //This all needs to be moved to Yikes.m. LocationManager doesn't know/care about this
    [[MultiYManGAuthDispatcher sharedInstance] didEnterYManRegion:nil];
    
    // Check if there is actually a valid and active stay
    if (self.userStay && self.userStay.isActive) {
        
//        [self fireDebugLocalNotification:@"Current Stay is Active"];
        
        // stop the timer if it was running to start the BLE Engine ASAP:
        //[self beginScanningForYikesHardwareRetryTimeout];
        
        if (!self.centralManager) {
            [self fireDebugLocalNotification:@"Had to re-initialize central manager"];
            //TODO: Set the userStayTo:
            [YBLEManager sharedManager];
        }
        
        if (self.dataDelegate) {
            [self.dataDelegate updateStayInfo];
            [self fireDebugLocalNotification:@"Data Delegate requested to update stay info..."];
        }
        else {
//            [self fireDebugLocalNotification:@"WARNING:\nNo Data Delegate!!!"];
        }
        
    }
    else {
        if (self.dataDelegate) {
            [self.dataDelegate updateStayInfo];
            [self fireDebugLocalNotification:@"Data Delegate requested to update stay info..."];
        }
        else {
            [self fireDebugLocalNotification:@"WARNING:\nNo Data Delegate!!!"];
        }
    }
    [self updateProximityStateDelegateWithState:kProximityStateInside];
    
    [self beginScanningForYikesHardware];
    
}

-(void)handleExitedRegion {
    
    if (self.debugDelegate) {
        [self.debugDelegate foundYMEN:@"Outside"];
        [self.debugDelegate informationUpdated:@""];
        [self.debugDelegate yLinkUpdate:@""];
        [self.debugDelegate elevatorYLinkUpdate:@""];
    }
    
    [self updateProximityStateDelegateWithState:kProximityStateOutside];
    
    [self stopBLEActivity];
    
//    [self fireDebugLocalNotification:@"Just exited yikes beacon region"];
}


#pragma mark - UILocalNotification
- (void)fireLocalNotification:(NSString *)message {
    if (_showDebugNotifications) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = [NSString stringWithFormat:@"%@", message];
            localNotif.alertAction = NSLocalizedString(@"Relaunch", @"Relaunch");
//            localNotif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
    }
}

- (void)fireDebugLocalNotification:(NSString *)message {
#ifdef DEBUG
    if (_showDebugNotifications) {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = [NSString stringWithFormat:@"%@", message];
            localNotif.alertAction = NSLocalizedString(@"Relaunch", @"Relaunch");
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
    }
#endif
}

#pragma mark - Debug Area

- (void)debugAreaFor:(NSString *)device event:(NSString *)event {
    if ([device isEqualToString:kDeviceYLink]) {
        if ([event isEqualToString:kEventNotFound]) {
            if ([self.debugDelegate respondsToSelector:@selector(yLinkUpdate:)]) {
                [self.debugDelegate yLinkUpdate:[NSString stringWithFormat:@"%@", event]];
            }
        }
    }
}

#pragma mark - Ble Triangle Failures reporting

- (void)bleTriangleFailureWithPeripheral:(CBPeripheral*) peripheral error:(NSError*) error {
    GuestAuth* gAuth = [self.connectionManager guestAuthForYLinkPeripheral:peripheral];
    
    if(gAuth) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"yLink error: %@\nError detail: %@", gAuth.trackID, error]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        DLog(@"yLink error: %@", gAuth);
    }
    else {
        YMan* aYMan = [self.connectionManager yManFromPeripheral:peripheral];
        if (aYMan) {

            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"yMAN error: %@\nError detail: %@", aYMan.macAddress, error]
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            [[MultiYManGAuthDispatcher sharedInstance] failedToConnectPYMan:aYMan.macAddress];
            DLog(@"yMan error: %@", aYMan);
        }
    }
    
    DLog(@"Error: %@", error);
}

#pragma mark - environment

- (NSString *)API_env {
    NSString *env = @"PROD";
    NSNumber *api = [[NSUserDefaults standardUserDefaults] valueForKey:@"apiSelectedKey"];
    if (api) {
        if (api.intValue == 255) {
            env = @"QA";
        }
        else if (api.intValue == 155) {
            env = @"DEV";
        }
        // by default it's PROD
    }
    return env;
}

#pragma mark - Logging Related


//Here for backwards compatibility, use logMessage:showInDebugView:isError instead
//- (void)logMessageToDebugView:(NSString *)logMsg isError:(BOOL)isError{
//
//    [self logMessage:logMsg showInDebugView:YES isError:isError];
//    
//    //TODO: Handle error types
//
//}

//- (void)logMessage:(NSString *)message showInDebugView:(BOOL)showDebug isError:(BOOL)isError {
//
//    if (self.isDebugModeEnabled) {
//        //TO DISPLAY
//        
//        NSString *timestamp = [self.debugDateFormatter stringFromDate:[NSDate date]];
//        NSString *logStr = [NSString stringWithFormat:@"%@ %@", timestamp, message];
//       
//        if (showDebug) {
//            // Error
//            [[YKSCentralizedLogger sharedLogger] logMessage:logStr withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
//        }
//        
//        if ([self.astinusLoggerDelegate respondsToSelector:@selector(didReceiveLogMessage:)] &&
//            self.isAstinusLoggerEnabled) {
//                [self.astinusLoggerDelegate didReceiveLogMessage:logStr];
//            }
//        
//        DLog(@"%@", logStr);
//        
//        //TO LOG
//        if (isError) {
//            
//            DLog(@"Error: %@", logStr);
//            
//            [[YLogReporter sharedInstance] logErrorAndLogDebugMessage:logStr isError:YES];
//            
//        } else {
//            [[YLogReporter sharedInstance] logErrorAndLogDebugMessage:logStr isError:NO];
//            
//        }
//    }
//    else {
//        DLog(@"self.isDebugModeEnabled is NO");
//    }
//}


//for Backwards compatibility DELETE when transitioned to Engine
-(BOOL)isInsideYikesRegion {
   
    return [[YKSLocationManager sharedManager] isInsideYikesRegion];
    
}


//TODO: Add calls for Astinus logger
//- (void)logMessage:(NSString *)message showInDebugView:(BOOL)showDebug isError:(BOOL)isError {
//
//    if (self.isDebugModeEnabled) {
//        //TO DISPLAY
//        
//        NSString *timestamp = [self.debugDateFormatter stringFromDate:[NSDate date]];
//        NSString *logStr = [NSString stringWithFormat:@"%@ %@", timestamp, message];
//       
//        if (showDebug) {
//            
//            if (self.consoleMessagesDelegate &&
//                [self.consoleMessagesDelegate respondsToSelector:@selector(bleLogMessagePosted:isError:)]) {
//                
//                [self.consoleMessagesDelegate bleLogMessagePosted:logStr isError:isError]; //To display
//            }
//            else {
//                DLog(@"No delegate or delegate doesn't respond to selector bleLogMessagePosted:isError:");
//            }
//            
//        }
//        
//        if ([self.astinusLoggerDelegate respondsToSelector:@selector(didReceiveLogMessage:)] &&
//            self.isAstinusLoggerEnabled) {
//                [self.astinusLoggerDelegate didReceiveLogMessage:logStr];
//            }
//        
//        DLog(@"%@", logStr);
//        
//        //TO LOG
//        if (isError) {
//            
//            DLog(@"Error: %@", logStr);
//            
//            [[YLogReporter sharedInstance] logErrorAndLogDebugMessage:logStr isError:YES];
//            
//        } else {
//            [[YLogReporter sharedInstance] logErrorAndLogDebugMessage:logStr isError:NO];
//            
//        }
//    }
//    else {
//        DLog(@"self.isDebugModeEnabled is NO");
//    }
//   
//    
//}


#pragma mark -
#pragma mark Important delegate callbacks

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
 
    self.currentPeripheral = peripheral;
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didDiscoverPeripheral peripheral: %@ advertisementData: %@", peripheral, advertisementData);
        return;
    }
  
    //is it a yMAN?
    YMan * yMan = [self.connectionManager yManFromAdvertisingUUID:[self firstUUIDFromAdvertisementData:advertisementData]];
    if (yMan) {
        
        //When running in the background, we need some BLE activity to keep us "awake"
        //We now always scan for primary yMen so this method gets called, but we only connect if
        //There are no valid guest auths.
        //TODO: determine how to fit multi-access with this approach

        if ([[YMotionManager sharedManager] isStationary]) {
            if (self.alreadyShowedStationaryLog == NO) {
                
                [[YKSLogger sharedLogger] logMessage:@"Device is Stationary, not returning to yMAN"
                                                 withErrorLevel:YKSErrorLevelInfo
                                                        andType:YKSLogMessageTypeBLE];
                
                self.alreadyShowedStationaryLog = YES;
            } else {
                //we want to log it every time, but only show it once, above
                
                [[YKSLogger sharedLogger] logMessage:@"Device is Stationary, not connecting to yMAN"
                                                 withErrorLevel:YKSErrorLevelInfo
                                                        andType:YKSLogMessageTypeBLE];
            }
            
            return;
            
        } else {
            self.alreadyShowedStationaryLog = NO;
        }
        
        if (yMan.blackListed) {
            DLog(@"Temporarily avoiding connecting to blacklisted yMAN %@", yMan.advertisingUUID);
//            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Temporarily avoiding connecting to blacklisted yMAN %@", yMan.advertisingUUID]
//                                             withErrorLevel:YKSErrorLevelInfo
//                                                    andType:YKSLogMessageTypeBLE];
            
            return;
        }
        
        if (![self.connectionManager shouldConnectToYMan:yMan]) {// && ![self.connectionManager areThereAnyUnsuccesfulGuestAuthsForYMan:yMan]) {
            DLog(@"LOG: Should NOT connect to %@ returns", yMan.macAddress);
//            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"LOG: Should NOT connect to %@ returns", yMan.macAddress] withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
            return;
        } else if (yMan.peripheral.state != CBPeripheralStateDisconnected) { //TODO: this check should be included in "shouldConnect" method
            DLog(@"didDiscover: yMAN already connecting, connected, returning");
//            [[YKSLogger sharedLogger] logMessage:@"didDiscover: yMAN already connecting, connected, returning" withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
            return;
        }
        
        DLog(@"Did discover: %@", [self firstUUIDFromAdvertisementData:advertisementData]);
        
        yMan.peripheral = peripheral;
        
        [[MultiYManGAuthDispatcher sharedInstance] connectToYMan:yMan.macAddress];
        
        [self connectToYMan:yMan];
        
        return;
        
    }
    
    if ([self isPeripheralElevatorYLink:advertisementData]) {
       
        [self addRSSI:RSSI toReadingsDictionaryFromPeripheral:peripheral];
        
        return;
    }
   
    
    BOOL shouldConnect = NO;
  
    //Get the guest auth (aka room auth) object if it exists
    GuestAuth * guestAuth = [self.connectionManager guestAuthForAdvertisementData:advertisementData];
    
    if (guestAuth && !guestAuth.isTimerExpired)  {
    
        guestAuth.yLinkPeripheral = peripheral; //old way, to be deleted
        
        guestAuth.yLink.peripheral = peripheral;
       
        [[MultiYManGAuthDispatcher sharedInstance] discoveredGA:guestAuth.trackID pYMan:guestAuth.yMan.macAddress];
        
//        [self fireDebugLocalNotification:[NSString stringWithFormat:@"Disc. yL w/ trID %@", guestAuth.trackID]];
        
        //[self removeYLinkAdvertisingUUIDAndResumeScanning:guestAuth.yLinkAdvertisementCombinedUUID];
        
        if ([self.debugDelegate respondsToSelector:@selector(yLinkUpdate:)]) {
            [self.debugDelegate yLinkUpdate:@"Connecting..."];
        }
        
        //[self stopYLinkTrackIDSessionTimer]; //TODO: what replaces this in multi? is this still being started?
        //[self stopYLinkNoAdvertisementFoundTimer]; //Same as above
        
        if (RSSI.intValue > guestAuth.connectRSSIThreshold && RSSI.intValue != 127) {
            
            //Call delegate method
            if ([self.guestEventDelegate respondsToSelector:@selector(connectingToDoor:)]) {
                [self.guestEventDelegate connectingToDoor:guestAuth.roomNumber];
            }
            
            [guestAuth updateStayOrAmenityConnectionStatus:kYKSConnectionStatusConnectingToDoor];
            
            DLog(@"RSSI %i greater than %li, connecting", RSSI.intValue, (long)guestAuth.connectRSSIThreshold);
            shouldConnect = YES;
        } else {
            
            //The timer is not expired, but we are trying to connect if in range
            if ([self.guestEventDelegate respondsToSelector:@selector(receivedAuthorization:)]) {
                [self.guestEventDelegate receivedAuthorization:guestAuth.roomNumber];
            }
            
            [guestAuth updateStayOrAmenityConnectionStatus:kYKSConnectionStatusScanningForDoor];
            
            DLog(@"RSSI %i less than %li, not connecting", RSSI.intValue, (long)guestAuth.connectRSSIThreshold);
            shouldConnect = NO;
        }
        
        [[MultiYManGAuthDispatcher sharedInstance] discoveredDoorforGA:guestAuth.trackID roomNumber:guestAuth.roomNumber pYMan:guestAuth.yMan.macAddress RSSI:RSSI];
        
        //Multi: Wait for last guest auth from yMAN:
    }
    
    if (shouldConnect) {
        [self connectToPeripheral:peripheral];
    }
    
}

//TODO: Get rid of this debug area code and send a notification to update the debug area instead - the debug area should reflect the BLE engine state at any time
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didConnectPeripheral: %@", peripheral);
        return;
    }
    
    
    if (peripheral.name && [peripheral.name rangeOfString:@"iphone" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSString *report = [NSString stringWithFormat:@"%@ UT:%@ Connected to %@ id %@ Room: %@ %@",
                            [self API_env],
                            [YKSSessionManager getCurrentUser].email,
                            peripheral.name,
                            peripheral.identifier,
                            self.userStay.room_number,
                            [YKSDeviceHelper fullGuestAppVersion]];
        
        
        [[MultiYManGAuthDispatcher sharedInstance] sendCriticalError:[NSError errorWithDomain:@"co.yikes.BLEManager" code:1 userInfo:
                                          @{
                                            NSLocalizedDescriptionKey:report
                                            }]];
    }
    //Only discover services that are currently necessary, based on what we need to write
    NSMutableSet * servicesToDiscover = [NSMutableSet setWithCapacity:3];
   
    YMan * yMan = [self.connectionManager yManFromPeripheral:peripheral];
    
    if (yMan) {
        
        [yMan didConnectToYMan];
        
        [servicesToDiscover addObject:self.yMANServiceUUID];
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Connected to yMAN %@ (name: %@)", yMan.macAddress, peripheral.name]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        [self fireDebugLocalNotification:@"Connected to yMAN!"];
        
        [self.centralManager stopScan];
        peripheral.delegate = self;
        [peripheral discoverServices:[NSArray arrayWithArray:[servicesToDiscover allObjects]]];
        //[peripheral discoverServices:nil];
        return;
    }
    
    else if ([peripheral isEqual:self.connectionManager.elevatorYLink]) {
        
        [servicesToDiscover addObject:self.yLinkServiceUUID];
        
        if ([self.debugDelegate respondsToSelector:@selector(connectedToDevice:)]) {
            [self.debugDelegate connectedToDevice:kDeviceElevatorYLink];
        }
        
        // UUID doesn't change on 1 device once it's been discovered and attributed an NSUUID
        NSUUID *uuid = peripheral.identifier;
        NSUInteger elevatorIndex;
        
        if ([self.elevatorsIdentifications indexOfObject:uuid] == NSNotFound) {
            [self.elevatorsIdentifications addObject:uuid];
        }
        
        elevatorIndex = [self.elevatorsIdentifications indexOfObject:uuid];
        

        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Connected to Elevator #%li (name: %@)", (unsigned long)elevatorIndex,
                                                         peripheral.name]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        [self fireDebugLocalNotification:@"Connected to Elevator!"];
       
        if ([self.guestEventDelegate respondsToSelector:@selector(connectedToDoor:)]) {
            [self.guestEventDelegate connectedToDoor:@"Elevator"];
        }
        
    }
    else if ([self.connectionManager isPeripheralARoom:peripheral]) {
        
        //Tells the timer to stop (also logs)
        [self.connectionManager didConnectToYLinkPeripheral:peripheral];
        
        peripheral.delegate = self;
        
        [servicesToDiscover addObject:self.yLinkServiceUUID];
        
        if ([self.debugDelegate respondsToSelector:@selector(connectedToDevice:)]) {
            [self.debugDelegate connectedToDevice:kDeviceYLink];
        }
        
        GuestAuth * guestAuth = [self.connectionManager guestAuthForYLinkPeripheral:peripheral];
        
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Connected to yLink %@ (name: %@)\nDoor: %@",
                                                         guestAuth.trackID, peripheral.name, guestAuth.roomNumber]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        [self fireDebugLocalNotification:[NSString stringWithFormat:@"Connected to door %@", guestAuth.roomNumber]];
   
        
        if ([self.guestEventDelegate respondsToSelector:@selector(connectedToDoor:)]) {
            [self.guestEventDelegate connectedToDoor:guestAuth.roomNumber];
        }
        
        [guestAuth updateStayOrAmenityConnectionStatus:kYKSConnectionStatusConnectedToDoor];
        
    }
    
    else {

        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Did connect to Unknown peripheral %@ (name: %@)",
                                                         peripheral, peripheral.name]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
    }
    
    [peripheral discoverServices:[NSArray arrayWithArray:[servicesToDiscover allObjects]]];
    
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (error) {
        
        if (error.code != 7 && error.code != 6) {
#ifdef DEBUG
//            AudioServicesPlayAlertSound(1057);
#endif
        }
        else {
            DLog(@"Expected disconnect from remote device: %@", error);
        }
    }
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything on didDisconnectPeripheral: %@", peripheral);
        return;
    }
    
    
    NSString * deviceName;
   
    if ([self.connectionManager isPeripheralAPrimaryYMAN:peripheral]) {
        
        YMan * yMAN = [self.connectionManager yManFromPeripheral:peripheral];
        
        [[MultiYManGAuthDispatcher sharedInstance] disconnectedPYMan:yMAN.macAddress];
        
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Disconnected from yMan %@ (name: %@)",
                                                         yMAN.macAddress, peripheral.name]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
       
        [yMAN didDisconnectFromYMan];
        
        //[self stopYMANDisconnectTimer];
       
        BOOL isError = NO;
        // even if there is an unkown error, always check if we already got a valid room auth from the yMAN before
        // making another attempt:
        if (error && error.code != 7 && error.code != 6) {
           
            if (error.code == 10) {
                [[YKSLogger sharedLogger] logMessage:@"Error code 10 detected" withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
               
                [[YKSErrorReporter sharedReporter] reportErrorWithType:kBLEErrorCode10];
                
            }
            
            [[MultiYManGAuthDispatcher sharedInstance] failedToConnectPYMan:yMAN.macAddress];
            
            // Always log these errors to the console if running off of Xcode (Debug / Dev mode)
#ifdef DEBUG
            NSString * message = [NSString stringWithFormat:@"Error on disconnect from yMan %li times", (long)[yMAN numberOfConnectionFailures]];

            [[YKSLogger sharedLogger] logMessage:message
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
#else
            BOOL maxRetries = [yMAN didFailOnDisconnect];
            if (maxRetries) {
                NSString * message = [NSString stringWithFormat:@"Failed to establish a good connection with yMan after attempting %i times", YMAN_RECONNECT_TRIALS];
                [[YKSLogger sharedLogger] logMessage:message
                                      withErrorLevel:YKSErrorLevelError
                                             andType:YKSLogMessageTypeBLE];
            }
            
#endif
            isError = YES;
        }
        
        // Disconnected from yMan
        
        if (isError) {
            if ([yMAN shouldRetryConnection]) {
               
                [self connectToYMan:yMAN];
            }
        }        
    }
    
    else if ([peripheral isEqual:self.connectionManager.elevatorYLink]) {
        
        // Only reattempt if the error code was different from Code=7 "The specified device has disconnected from us." and Code=6 "The connection has timed out unexpectedly."
        // like code=10 "The connection has failed unexpectedly."
        if (error && error.code != 7 && error.code != 6 && self.numberOfElevatorConnectTrials < YLINK_RECONNECT_TRIALS) {
            [self retryElevatorConnection];
            return;
        }
        else {
            
            self.elevatorConnectionAttemptFailed = YES;
            
            //TODO: Report failure event to YLogReporter
            
            // NSString *message = [NSString stringWithFormat:@"\n###########################\nFAILED TO ATTEMPT TO CONNECT %i TIMES\n\nGIVING UP ON ELEVATOR\n###########################", self.numberOfElevatorConnectTrials + 1];
            
            [[YKSLogger sharedLogger] logMessage:[NSString
                                                             stringWithFormat:@"Disconnected from Elevator (name: %@)",
                                                             peripheral.name]
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeBLE];
            //DLog(@"Disconnected from Elevator");
            
            [self updateDebugAreaAfterDisconnectWith:kDeviceElevatorYLink];
            
            [self fireDebugLocalNotification:@"Disconnected from Elevator"];
            
            if ([self.guestEventDelegate respondsToSelector:@selector(disconnectedFromDoor:)]) {
                [self.guestEventDelegate disconnectedFromDoor:@"Elevator"];
            }
            
            deviceName = kDeviceElevatorYLink;
            
            // This should fix the issue where it says "elevator yLink should be connected or connecting" and it's never connecting
            self.connectionManager.elevatorYLink = nil;
            
            [self resetConditionsToWriteToElevator];
            
            // allow a small timeout before the next round
            //[self startElevatorYLinkNewScanTimer];
        }
        
    }
    else {
        GuestAuth * guestAuth = [self.connectionManager guestAuthForYLinkPeripheral:peripheral];
        if (guestAuth) {
            
#ifdef DEBUG
            //AudioServicesPlayAlertSound(1025);
#endif
            
            //Multi: disconnected from a yLink: check error code and individual trackID session timer, then
            // retry for this specific yLink: [self retryConnectionFor:peripheral];
            
            [[MultiYManGAuthDispatcher sharedInstance] disconnectedGA:guestAuth.trackID pYMan:guestAuth.yMan.macAddress];
            
            [[YKSLogger sharedLogger] logMessage:[NSString
                                                             stringWithFormat:@"Disconnected from yLink %@ (name: %@)",
                                                             guestAuth.trackID, peripheral.name]
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeBLE];
            
            [self fireDebugLocalNotification:@"Disconnected from yLink"];
            
            //Call delegate method
            if ([self.guestEventDelegate respondsToSelector:@selector(disconnectedFromDoor:)]) {
                [self.guestEventDelegate disconnectedFromDoor:guestAuth.roomNumber];
            }
            [guestAuth updateStayOrAmenityConnectionStatus:kYKSConnectionStatusDisconnectedFromDoor];
            
            //TODO: Multi: this won't work anymore... need to pass the info for the specific room / yLink:
            
            if ([[YKSLocationManager sharedManager] isInsideYikesRegion]) {
                
                [self updateProximityStateDelegateWithState:kProximityStateInside];
            }
            else {
                [self updateProximityStateDelegateWithState:kProximityStateOutside];
            }
           
            
        }
    }
    
}

- (void)updateDebugAreaAfterDisconnectWith:(NSString *)deviceName {
    if ([self.debugDelegate respondsToSelector:@selector(disconnectedFromPeripheral:)]) {
        // making sure there are no race conditions on different threads...
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (overridden || elevatorOverridden) {
                
                [self.debugDelegate disconnectedFromPeripheral:deviceName];
                
                // reset
                if ([deviceName isEqualToString:kDeviceYLink] && overridden) {
                    overridden = NO;
                    if ([self.debugDelegate respondsToSelector:@selector(yLinkUpdate:)]) {
                        [self.debugDelegate yLinkUpdate:@"Overridden!"];
                    }
                }
                else if ([deviceName isEqualToString:kDeviceElevatorYLink] && elevatorOverridden) {
                    elevatorOverridden = NO;
                    if ([self.debugDelegate respondsToSelector:@selector(elevatorYLinkUpdate:)]) {
                        [self.debugDelegate elevatorYLinkUpdate:@"Overridden!"];
                    }
                }
                
            }
            else {
                // don't show if overriden to keep the overriden label
                [self.debugDelegate disconnectedFromPeripheral:deviceName];
            }
        });
      
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Disconnecting from %@",
                                                         deviceName]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"Disconnecting from %@", deviceName);
    }
    else {
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"WARNING: Delegate is not responding to disconnectedFromPeripheral: - peripheral was %@",
                                                         deviceName]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"WARNING: Delegate is not responding to disconnectedFromPeripheral: - peripheral was %@", deviceName);
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (error) {
        NSString *message = [NSString stringWithFormat:@"Error while discovering services on peripheral %@\n for services %@\n\n%@", peripheral, [peripheral services], error];
        DLog(@"%@", message);
//        [self fireDebugLocalNotification:message];
    }
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didDiscoverServices peripheral: %@", peripheral);
        return;
    }
    
    if (peripheral.services.count == 0) {
        
        if (error.code == 3) {
            [[YKSErrorReporter sharedReporter] reportErrorWithType:kBLEErrorCode3];
        }

        NSString *message = [NSString stringWithFormat:@"No services found on peripheral %@", peripheral];

        [[YKSLogger sharedLogger] logMessage:message
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        [self bleTriangleFailureWithPeripheral:peripheral error:error];
        
        return;
    }
    
    for (CBService * service in peripheral.services) {
      
        if ([service.UUID isEqual:self.yMANServiceUUID]) {
          
            [peripheral discoverCharacteristics:@[self.messageCharacteristicUUID] forService:service];
            break;
            
         /*
          
          Printing description of service:
          <CBService: 0x14ea5e30, isPrimary = YES, UUID = C3221178-2E83-40E2-9F12-F07B57A77E1F>
          Printing description of peripheral:
          <CBPeripheral: 0x14d921e0, identifier = 25AAFC21-AE59-9921-FD39-90E95D4F2ACF, name = Unnamed, state = connected>
          (lldb) po peripheral.services
          <__NSArrayM 0x14e6cd50>(
          <CBService: 0x14ea5e30, isPrimary = YES, UUID = C3221178-2E83-40E2-9F12-F07B57A77E1F>,
          <CBService: 0x14e9f5f0, isPrimary = YES, UUID = F7E66311-D667-4C2F-A1DD-BD3BF1B40DB6>
          )

          WARNING: the yMan2YLink service UUID is the same as yLink2yPHONE. so MAKE SURE it's a yMAN and not a yLink
          */
            
          //If we've already seen a yLink, check that it's not that. This is due to the decision to use the same
          //UUID for yMan2yPhone + yMan2yLink.
            
        }
        
        else if ([service.UUID isEqual:self.yLinkServiceUUID]) {
            
            GuestAuth *guestAuth = [self.connectionManager guestAuthForYLinkPeripheral:peripheral];
            if (guestAuth) {
                //Multi: discover characteristic
                // Not much to do...
                
            }
            else {
                
                self.elevatorYLinkService = service;
            }
            
            [peripheral discoverCharacteristics:@[self.yLinkWriteCharacteristicUUID] forService:service];
            
            break;
        }
        
        else {
            
            [[YKSLogger sharedLogger] logMessage:[NSString
                                                             stringWithFormat:@"Unknown service on peripheral: %@ \n\nSkipping",
                                                             peripheral]
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeBLE];
            //DLog(@"Unknown service on peripheral: %@ \n\nSkipping", peripheral);
        }
        
        
    }
    
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    //DLog(@"Did discover characteristics: %@", service.characteristics);
    
    if (error) {
        NSString *message = [NSString stringWithFormat:@"Error while discovering services on peripheral %@\n for services %@\n and characteristics %@\n\n%@", peripheral, service, [service characteristics], error];
        DLog(@"%@", message);
        [self fireDebugLocalNotification:message];
    }
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didDiscoverCharacteristicsForService: %@", service);
        return;
    }
    
    if ([service.UUID isEqual:self.yMANServiceUUID]) {
      
        YMan * yMan = [self.connectionManager yManFromPeripheral:peripheral];
        
        if (!yMan) {
            
            [[YKSLogger sharedLogger] logMessage:@"Discovered characteristic: Could not retreive yMAN from manager"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            return;
        }
       
        //TODO: double check if this assignment is necessary. the peripheral passed is
        //probably identical to the yMan one already
        yMan.peripheral = peripheral; //local peripheral object now has discovered services + characteristics
        
        if ([self.debugDelegate respondsToSelector:@selector(connectedToDevice:)]) {
            [self.debugDelegate connectedToDevice:@"yMAN"];
        }
        
        for (CBCharacteristic * characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:self.messageCharacteristicUUID]) {
                yMan.characteristic = characteristic;
            }
        }
       
        if ([self.connectionManager shouldRequestAllGuestAuths:yMan]) {
            [self.connectionManager resetYLinksForYMan:yMan];
            
            [self requestAllGuestAuthsFromYMAN:yMan];
        } else {
            
            NSArray * renewals = [self.connectionManager yLinkMACAddressesForRenewRequest:yMan];
            
            if (renewals && renewals.count > 0) {
                [self renewGuestAuthForYLinkAddresses:renewals fromYMAN:yMan];
            }
            
        }
        
        
        
        
    } else if ([service.UUID isEqual:self.yLinkServiceUUID]) {
        
        for (CBCharacteristic * characteristic in service.characteristics) {
            
            if ([characteristic.UUID isEqual:self.yLinkWriteCharacteristicUUID]) {
                
                if ([self.connectionManager isPeripheralARoom:peripheral]) {
                    //TODO: deal with debug area
                    // debug area info update // NB this is now updated all the time. we may need to do this in writeRoomAuthToYLink
                    if ([self.debugDelegate respondsToSelector:@selector(connectedToDevice:)]) {
                        [self.debugDelegate connectedToDevice:kDeviceYLink];
                    }
                    
                    //[self stopYLinkTrackIDSessionTimer]; //Multi: no longer stop this timer. What else do we need to do here wrt "single timer"?
                    
                    //This method will check whether it should actually write or not
                    [self writeRoomAuthToYLink:peripheral atCharacteristic:characteristic];
                        
                } else if ([service isEqual:self.elevatorYLinkService]) {
                    self.connectionManager.elevatorWriteCharacteristic = characteristic;
                    
                    [[YKSLogger sharedLogger] logMessage:@"Going to write to the elevator yLink (static token)"
                                                     withErrorLevel:YKSErrorLevelInfo
                                                            andType:YKSLogMessageTypeBLE];
                    
                        //DLog(@"Going to write to the elevator yLink (static token)");
                    [self writeToElevatorYLink];
                        
                }
                else {
                    NSString *message = [NSString
                                         stringWithFormat:@"WARNING: didDiscoverCharacteristicsForService - Unknown characteristic for peripheral %@ and service %@\n\nCharacteristic: %@",
                                         peripheral, service, characteristic];
                    
                    [[YKSLogger sharedLogger] logMessage:message
                                                     withErrorLevel:YKSErrorLevelInfo
                                                            andType:YKSLogMessageTypeBLE];
                    //DLog(@"WARNING: didDiscoverCharacteristicsForService - Unknown characteristic for peripheral %@ and service %@\n\nCharacteristic: %@", peripheral, service, characteristic);
                }
                
                // done - we found our yLink or elevator write characteristic
                break;
                
            } //if
        } //for
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error.code != 0) {

#ifdef DEBUG
//        AudioServicesPlayAlertSound(1057);
#endif
        
        [self fireDebugLocalNotification:[NSString stringWithFormat:@"Error reading a characteristic:\n%@", error]];
      
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Error: %@", error]
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        //DLog(@"Error: %@", error);
        
        return;
    }
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didUpdateValueForCharacteristic: %@", characteristic);
        return;
    }
    
    if ([characteristic.UUID isEqual:self.messageCharacteristicUUID]) {
        
       
        YMan * yMan = [self.connectionManager yManFromPeripheral:peripheral];
        GuestAuth * guestAuth = [self.connectionManager addNewGuestAuthWithYMan:yMan andMessage:characteristic.value];
        
        switch (guestAuth.authType) {
            case kGuestAuthTypeAllZeros:
             
                [[MultiYManGAuthDispatcher sharedInstance] receivedStopMsgPYMan:yMan.macAddress];
                
                //If we've *only* gotten this without any ohter guest auths, we should check back with yCentral
                if (![self.connectionManager areThereAnyActiveGuestAuthsForYMan:yMan]) {
                    
                    [self requestStayInfoUpdate];
                    
                    //Also, insert a "placeholder" guest auth to prevent going back to this yMan.
                    //[self.connectionManager insertPlaceholderGuestAuthForYMan:yMan];
                    
                    yMan.blackListed = YES;
                    NSTimeInterval blacklistTime = YMAN_BLACKLIST_DURATION;
                    
                    NSString *blackListedMessage = [NSString stringWithFormat:@"yMAN %@ was BLACKLISTED for %.2fs\nReason: %@", yMan.macAddress, blacklistTime, @"yMAN returned an All-Zeros message on first READ"];
                    
                    [[YKSLogger sharedLogger] logMessage:blackListedMessage
                                                     withErrorLevel:YKSErrorLevelError
                                                            andType:YKSLogMessageTypeBLE];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(blacklistTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        yMan.blackListed = NO;
                    });
                    
                    NSString *report = [NSString stringWithFormat:@"%@ UT:%@ yMAN %@ BLACKLISTED Reason: %@ Room: %@ %@", [self API_env], [YKSSessionManager getCurrentUser].email, yMan.macAddress, @"All-0 msg on 1st READ", self.userStay.room_number, [YKSDeviceHelper fullGuestAppVersion]];
                    
                    [[MultiYManGAuthDispatcher sharedInstance] sendCriticalError:[NSError errorWithDomain:@"co.yikes.BLEManager"
                                                                         code:1 userInfo:
                                                      @{
                                                        NSLocalizedDescriptionKey:report
                                                        }]];
                    
                    NSString *criticalMessage = [NSString stringWithFormat:@"CRITICAL ERROR DETECTED - All-0 MESSAGE ON 1ST READ FROM P.YMAN:\n%@", report];
                    
                    [[YKSLogger sharedLogger] logMessage:criticalMessage
                                                     withErrorLevel:YKSErrorLevelError
                                                            andType:YKSLogMessageTypeBLE];
                    
                    if ([self.debugDelegate respondsToSelector:@selector(foundYMEN:)]) {
                        [self.debugDelegate foundYMEN:@"All-Zeros TrackID"];
                    }
                    
                }
                
                //Transaction has been sucessful, reset the fail count
                [yMan resetDisconnectFail];
                //[self.centralManager cancelPeripheralConnection:peripheral];
                
                break;
                
            case kGuestAuthTypeValid:
                
                [self updateProximityStateDelegateWithState:kProximityStateYMAN];
                
                //[self beginProcedureToWriteRoomAuthToYLink];
                
                [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Received valid Guest Auth for room: %@ (expires in %f seconds)",
                                                      guestAuth.roomNumber,
                                                      guestAuth.timeoutSeconds]
                                                 withErrorLevel:YKSErrorLevelDebug
                                                        andType:YKSLogMessageTypeBLE];
                
                [self fireDebugLocalNotification:[NSString stringWithFormat:@"Received valid Guest Auth for room: %@", guestAuth.roomNumber]];
                
                //Call delegate method
                if ([self.guestEventDelegate respondsToSelector:@selector(receivedAuthorization:)]) {
                    [self.guestEventDelegate receivedAuthorization:guestAuth.roomNumber];
                }
                
                [guestAuth updateStayOrAmenityConnectionStatus:kYKSConnectionStatusScanningForDoor];
                
                //read again
                [self readStayTokenAndTrackIDFromYMAN:yMan];
                
                break;
                
                
            case kGuestAuthTypeTrackIDZeros:
                
            {
                [[YKSLogger sharedLogger] logMessage:@"Received Zero TrackID with Stay Token"
                                                 withErrorLevel:YKSErrorLevelInfo
                                                        andType:YKSLogMessageTypeBLE];
                
                NSString *report = [NSString stringWithFormat:@"%@ UT:%@ yMAN %@ 0-tID %@ Room %@ %@",
                                    [self API_env],
                                    [YKSSessionManager getCurrentUser].email,
                                    yMan.macAddress,
                                    @"All-0 msg on 1st READ",
                                    self.userStay.room_number,
                                    [YKSDeviceHelper fullGuestAppVersion]];
                
                [[MultiYManGAuthDispatcher sharedInstance] sendCriticalError:[NSError errorWithDomain:@"co.yikes.BLEManager" code:1 userInfo:
                                                  @{
                                                    NSLocalizedDescriptionKey:report
                                                    }]];
                
               
                //If we get a 0-trackID for a particular yLink, we don't want to renew it
                [self.connectionManager resetYLinksForYMan:yMan];
                
                [self readStayTokenAndTrackIDFromYMAN:yMan];
                
                break;
                
            }
                
            case kGuestAuthTypeNotExpectedRoom: {
                
                NSTimeInterval blacklistTime = 4.0;
                yMan.blackListed = YES;
                
                NSString *blackListedMessage = [NSString stringWithFormat:@"yMAN %@ was BLACKLISTED for %.2fs\nReason: %@", yMan.macAddress, blacklistTime, @"Room number does not match any in stays"];

               
                //ADD call to refresh stays
                [[YikesEngineMP sharedEngine] refreshUserInfoWithSuccess:^(YKSUserInfo *user) {
                    //
                } failure:nil];
                
                
                [[YKSLogger sharedLogger] logMessage:blackListedMessage
                                      withErrorLevel:YKSErrorLevelError
                                             andType:YKSLogMessageTypeBLE];
               
                
                [[YKSErrorReporter sharedReporter] reportErrorWithType:kBLEErrorNonMatchingAuth];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(blacklistTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    yMan.blackListed = NO;
                });
                

               [self readStayTokenAndTrackIDFromYMAN:yMan];
                
                
            }
                
            default:
                if ([self.debugDelegate respondsToSelector:@selector(foundYMEN:)]) {
                    [self.debugDelegate foundYMEN:@"All-Zeros TrackID"];
                }
                break;
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        
#ifdef DEBUG
//        AudioServicesPlayAlertSound(1057);
        
        if (![peripheral.name isEqualToString:@"Unnamed"]) {
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Must be a yLink: %@", peripheral] withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
        }
#endif
        
        [self bleTriangleFailureWithPeripheral:peripheral error:error];
        
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Write error: %@ for peripheral %@ and characteristic %@ ",
                                                         error, peripheral.identifier, characteristic.UUID]
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        [self fireDebugLocalNotification:[NSString stringWithFormat:@"Failed to write to %@", peripheral.name]];
        
        return;
    }
    
    if (self.isResettingBLEEngine) {
        DLog(@"Resetting BLE Engine - not doing anything after didWriteValueForCharacteristic: %@", characteristic);
        return;
    }
    
        
    if ([characteristic.UUID isEqual:self.messageCharacteristicUUID]) {
        
        //Wrote yPhoneID
        //[self logMessageToDebugView:@"Received write confirmation from yMAN" isError:NO];
        //DLog(@"Received write confirmation from yMAN");
        
//        [self fireLocalNotification:@"yMAN has been written to"];
       
        YMan * yMan = [self.connectionManager yManFromPeripheral:peripheral];
        
        if (!yMan) {
            
            [[YKSLogger sharedLogger] logMessage:@"didWrite yPhone id. Could not retrieve yMan from Manager."
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
        }
        else {
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Received write confirmation from yMAN %@", yMan.macAddress] withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeBLE];
        }
        
        [self readStayTokenAndTrackIDFromYMAN:yMan];
        
    }
    
    else if ([characteristic isEqual:self.connectionManager.elevatorWriteCharacteristic]) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Wrote to Elevator yLink %@", peripheral.name]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        [self fireDebugLocalNotification:[NSString stringWithFormat:@"Elevator yLink %@ has been written to", peripheral.name]];
        
    }
    
    else {
        
        if ([self.connectionManager guestAuthForYLinkPeripheral:peripheral]) {
            //Multi: means we just wrote to one of the yLinks
            
            [[YKSLogger sharedLogger] logMessage:[NSString
                                                             stringWithFormat:@"Received write confirmation from yLink %@\n\n\n",
                                                             peripheral.name]
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeBLE];
            
            //DLog(@"Received write confirmation from yLink");
            
            [self fireDebugLocalNotification:[NSString stringWithFormat:@"yLink %@ has been written to", peripheral.name]];
            
            [self updateProximityStateDelegateWithState:kProximityStateYLink];
            
            [self.connectionManager didWriteToPeripheral:peripheral];
           
            
#ifdef DEBUG
//            self.yLinkDisconnectTimer = [MSWeakTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(disconnectFromAllYLinksAndExpireGuestAuths) userInfo:nil repeats:NO dispatchQueue:self.centralQueue];
#endif
        }
        else {
            DLog(@"%@", [NSString stringWithFormat:@"Wrote to Unknown characteristic: %@\nProbably the Elevator characteristic...", characteristic]);
        }
    }
    
}


#pragma mark - 
#pragma mark - BLE Engine 0.2 Timer methods

-(dispatch_queue_t)serialQueue {
    return self.centralQueue;
}

//Note: Since we now deal with multiple yMen + yLinks, the objects representing each (YMan, GuestAuth) handle their own timers
//The timeouts, on the other hand, are here since this class handles all BLE events

-(void)yManConnectionTimedOut:(MSWeakTimer *)timer {
   
    YMan * yMan = [timer userInfo];

    if (yMan.peripheral.state == CBPeripheralStateConnected || yMan.peripheral.state == CBPeripheralStateDisconnected) {
        return;
        
    } else if (yMan.peripheral.state == CBPeripheralStateConnecting) {
        
        [self.centralManager cancelPeripheralConnection:yMan.peripheral];
        
    }
    
}

-(void)yManDisconnectTimedOut:(MSWeakTimer *)timer {
   
    YMan * yMan = [timer userInfo];
    
    if (yMan.peripheral.state == CBPeripheralStateDisconnected) {
        //if we are already disconnected, we don't need to do anything
        return;
    } else if (yMan.peripheral.state == CBPeripheralStateConnected || yMan.peripheral.state == CBPeripheralStateConnecting) {
       
        [self.centralManager cancelPeripheralConnection:yMan.peripheral];
         
    }
    
}


- (void)yLinkConnectionTimedOut:(NSString *)roomName {
   
   
    if ([self.guestEventDelegate respondsToSelector:@selector(disconnectedFromDoor:)]) {
        [self.guestEventDelegate disconnectedFromDoor:roomName];
    }
    
    
}

#pragma mark -
#pragma mark Timer methods


-(void)overrideYLinkTimeout {
    
    [self disconnectFromAllYLinksAndExpireGuestAuths];
    
    return;
}

- (void)disconnectFromyLinkWithTrackID:(NSData *)trackID {
    
    CBPeripheral *yLink = [self.connectionManager yLinkPeripheralForGuestAuth:trackID];
    if (yLink) {
        [self.centralManager cancelPeripheralConnection:yLink];
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"User Override of yLink connection\n%@", trackID]
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
    }
    else {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Warning: User Override of yLink failed\n%@ not found", trackID]
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
    }
}

-(void)disconnectFromAllYLinksAndExpireGuestAuths {
   
    NSArray * connectedOrConnectedYLinks = [self.connectionManager connectedOrConnectingYLinks];
    
    if (connectedOrConnectedYLinks.count == 0) {
        return;
    }
    
    [[YKSLogger sharedLogger] logMessage:@"Guest App is disconnecting from ALL yLinks"
                                     withErrorLevel:YKSErrorLevelError
                                            andType:YKSLogMessageTypeBLE];
    
    for (CBPeripheral * yLink in [self.connectionManager connectedOrConnectingYLinks]) {
        
        [self.centralManager cancelPeripheralConnection:yLink];
        
    }
    
    [[MultiYManGAuthDispatcher sharedInstance] expireAllGuestAuths];
    
    [self.connectionManager expireAllGuestAuths];
    
    [self.connectionManager removeAllGuestAuths];
    
}

-(void)disconnectFromAllYMen {
   
    for (YMan * yMan in [self.connectionManager connectedOrConnectingYMen]) {
   
        [self.centralManager cancelPeripheralConnection:yMan.peripheral];
        
    }
    
}

-(void)disconnectFromElevator {
   
    if (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state != CBPeripheralStateDisconnected) {

        [self.centralManager cancelPeripheralConnection:self.connectionManager.elevatorYLink];
        
    }
    
}


- (void)overrideElevatorYLinkTimeout {
    
    //[self removeElevatorUUIDAndAndResumeScanning];
    
    if (self.connectionManager.elevatorYLink) {
        if (self.connectionManager.elevatorYLink.state != CBPeripheralStateDisconnected) {
            [self.centralManager cancelPeripheralConnection:self.connectionManager.elevatorYLink];
        }
    }
    
    elevatorOverridden = YES;
    
    if ([self.debugDelegate respondsToSelector:@selector(elevatorYLinkUpdate:)]) {
        [self.debugDelegate disconnectedFromPeripheral:kDeviceElevatorYLink];
        [self.debugDelegate elevatorYLinkUpdate:@"Overridden!"];
    }
    
    [self resetConditionsToWriteToElevator];
    //[self startScanningForElevatorYLink];
}

#pragma mark - elevator timers

-(void)startElevatorConnectTimer {
   
    [self stopElevatorConnectTimer];
   
    self.elevatorConnectTimer = [MSWeakTimer scheduledTimerWithTimeInterval:ELEVATOR_CONNECT_TIMEOUT target:self selector:@selector(elevatorConnectTimeout) userInfo:nil repeats:NO dispatchQueue:self.centralQueue];
    
}


-(void)stopElevatorConnectTimer{
   
    if (self.elevatorConnectTimer) {
        [self.elevatorConnectTimer invalidate];
        self.elevatorConnectTimer = nil;
    }
    
}

//TODO: should be adapted for multiaccess, in the connectionManager
-(void)elevatorConnectTimeout {
    
    [self stopElevatorConnectTimer];
   
    BOOL shouldAttemptReconnection = YES;
    
    if (self.connectionManager.elevatorYLink != nil) {
        
        if (self.connectionManager.elevatorYLink.state == CBPeripheralStateConnecting) {
            
            [[YKSLogger sharedLogger] logMessage:@"WARNING: Elevator timed out while trying to connect. Back to scanning..."
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            [self.centralManager cancelPeripheralConnection:self.connectionManager.elevatorYLink];
            
            //self.elevatorYLink = nil;
            
        }
        else if (self.connectionManager.elevatorYLink.state == CBPeripheralStateConnected) {
            
            [[YKSLogger sharedLogger] logMessage:@"WARNING: Timed out at same time as connected\nElevator Flow will continue as expected"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            shouldAttemptReconnection = NO;
        }
        else {
            [[YKSLogger sharedLogger] logMessage:@"Could not connect to Elevator. Back to scanning..."
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            //self.elevatorYLink = nil;
        }
        
    }
    
    if (shouldAttemptReconnection) {
        [self resetConditionsToWriteToElevator];
        // resume scanning with no timeout:
//        [self startScanningForElevatorYLink];
    }
    
}

- (void)connectToClosestElevator {

    if ([self isConnectedToElevator] || [[YMotionManager sharedManager] isStationary]) {
        return; //only want to connect to 1 at a time.
    }
    
    CBPeripheral *closest = [self closestPeripheralFromRSSIReadings:self.elevatorRSSIReadings];
    
    //[self logMessageToDebugView:[NSString stringWithFormat:@"Closest Elevator results: %@, %@", self.elevatorRSSIReadings, closest] isError:NO];
    //[self logMessageToDebugView:[NSString stringWithFormat:@"Closest Elevator is %@", closest] isError:NO];
    
    NSNumber * averageRSSI = self.elevatorRSSIReadings[closest][@"average"];
    
//    DLog(@"Average RSSI from closest elevator: %@", averageRSSI);
    
    if (closest && averageRSSI.floatValue > self.elevatorRSSIThreshold) {
        
        // TODO: Attribute a readable ID to the elevator
        // UUID doesn't change on 1 device once it's been discovered and attributed an NSUUID
        NSUUID *uuid = closest.identifier;
        NSUInteger elevatorIndex;
        
        if ([self.elevatorsIdentifications indexOfObject:uuid] == NSNotFound) {
            [self.elevatorsIdentifications addObject:uuid];
        }
        
        elevatorIndex = [self.elevatorsIdentifications indexOfObject:uuid];
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"DISCOVERED ELEVATOR #%li", (unsigned long)elevatorIndex]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        closest.delegate = self;
        self.connectionManager.elevatorYLink = closest;
       
        if ([self.guestEventDelegate respondsToSelector:@selector(connectingToDoor:)]) {
            [self.guestEventDelegate connectingToDoor:@"Elevator"];
        }
        
        [self.centralManager connectPeripheral:self.connectionManager.elevatorYLink options:nil];
    }
    else {
        //Discovered no Elevator
        //TODO: Add a logging method for this
        //[[YLogReporter sharedInstance] discoveredNoYMan_4b__GA_YMAN];
        
    }
    
    [self resetConditionsToWriteToElevator];
}

//TODO: move this method to connectionManager
-(BOOL)isConnectedToElevator {
    
    if (self.connectionManager.elevatorYLink && self.connectionManager.elevatorYLink.state == CBPeripheralStateConnected) {
        return YES;
    }
    else {
        return NO;
    }
    
}

#pragma mark - yMAN

- (NSString *)macAddressFromAdvUUID:(NSUUID *)advUUID {
    NSString *UUID = [advUUID UUIDString];
    // example: E621E1F8-C36C-495A-93FC-0C247A3E6E5F (always 36 in this format)
    if (UUID.length == 36) {
        // then use the characters from index 24
        NSString *macAddress = [UUID substringFromIndex:24];
        DLog(@"Mac address is %@", macAddress);
        return macAddress;
    }
    return nil;
}

- (void)stopDebugInfoTimer {
    if (self.debugInfoTimer) {
        [self.debugInfoTimer invalidate];
        self.debugInfoTimer = nil;
    }
}



-(void)stopAllTimers {
    
    [self stopDebugInfoTimer];
    [self stopElevatorConnectTimer];
}

#pragma mark -
#pragma mark CBCentralManager Delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
   
    [[YKSServicesManager sharedManager] handleBluetoothStateChanged];
    
    self.isBluetoothPoweredOn = YES;
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"CBCentralManagerState is %@", @(central.state)]
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        
        [[YKSLogger sharedLogger] logMessage:@"Bluetooth is ON"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        // Ensure iBeacon monitoring + ranging is ON
        // TODO: is this still necessary?
        [[YKSLocationManager sharedManager] startMonitoringRegion];
      
        //This will check conditions, no need to do it here
        [self beginScanningForYikesHardware];
        
        if ([self.dataDelegate respondsToSelector:@selector(onBLEKitStateChange:)]) {
            [self.dataDelegate onBLEKitStateChange:yksBluetoothRequirementFound];
        }
    }
    else if (central.state == CBCentralManagerStatePoweredOff) {
        
        self.isBluetoothPoweredOn = NO;
        
        [[YKSLogger sharedLogger] logMessage:@"Bluetooth is OFF"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeService];
        
        //TODO: Check why it was called twice
        [[YKSLogger sharedLogger] logMessage:@"Bluetooth is OFF"
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeService];
        
        if ([self.debugDelegate respondsToSelector:@selector(disconnectedFromPeripheral:)]) {
            
                [self.debugDelegate yLinkUpdate:@""];
            
                if ([self.debugDelegate respondsToSelector:@selector(informationUpdated:)]) {
                    [self.debugDelegate informationUpdated:@""];
                }
            
            if (self.connectionManager.elevatorYLink) {
                [self.debugDelegate disconnectedFromPeripheral:kDeviceElevatorYLink];
            }
            else {
                [self.debugDelegate elevatorYLinkUpdate:@""];
            }
        }
        
        // Bluetooth is OFF, assuming all connections are terminated immediately:
        
        // Update UI
        for (GuestAuth* guestAuth in self.connectionManager.activeGuestAuths) {
            if (guestAuth.roomNumber && guestAuth.roomNumber.length) {
                [self yLinkConnectionTimedOut:guestAuth.roomNumber];
            }
        }
        
        [[MultiYManGAuthDispatcher sharedInstance] expireAllGuestAuths];
        
        [self.connectionManager expireAllGuestAuths];
        
        [self.connectionManager removeAllGuestAuths];
        
        [self stopAllScanActivity];
       
    }
    else {
        
        CBManagerState state = self.centralManager.state;
        if (state == CBCentralManagerStateResetting) {
            
            [[YKSLogger sharedLogger] logMessage:@"Bluetooth is RESETTING"
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeService];
        }
        else if (state == CBCentralManagerStateUnknown) {
            
            [[YKSLogger sharedLogger] logMessage:@"Bluetooth is UNKNOWN"
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeService];
        }
        else if (state == CBCentralManagerStateUnauthorized) {
            
            [[YKSLogger sharedLogger] logMessage:@"Bluetooth is UNAUTHORIZED"
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeService];
        }
        else {
            
            [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Bluetooth is %@", @(state)]
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeService];
        }
        
        // Bluetooth is either in a bad state or resetting, wait until state ON:
        [self stopAllScanActivity];
        
        }
    }


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Will restore state. dict: %@", dict]
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
}



#pragma mark CBPeripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
  
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Did modify services. %@", invalidatedServices]
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
    //DLog(@"Did modify services. %@", invalidatedServices);
    
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"RSSI: %@", RSSI]
                          withErrorLevel:YKSErrorLevelInfo
                                 andType:YKSLogMessageTypeBLE];
    
    
}


-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    //[self sendInfoToDelegate:[NSString stringWithFormat:@"Subscribed to characteristic %@", characteristic.UUID]];
}

#pragma mark -
#pragma mark Basic CBCentralManager convenience methods

//wrapper method to check properties
-(void)writeValue:(NSData *)data toCharacteristic:(CBCharacteristic *)characteristic onPeripheral:(CBPeripheral *)peripheral{
    
    
    if (!characteristic) {
        if (self.callbackWithError) {
            self.callbackWithError([NSError errorWithDomain:@"co.yikes.bleError" code:1 userInfo:@{@"description": @"The characteristic has not been discovered", @"type": @"Exception"}]);
        }

        [[YKSLogger sharedLogger] logMessage:@"The characteristic has not been discovered"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        return;
    }
    
    if ([self isWriteEnabled:characteristic.properties]) {
        
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        //[self logMessageToDebugView:@"√ Writing with response!!" isError:NO];
        //DLog(@"√ Writing with response!!");
    } else if ([self isWriteWithoutResponseEnabled:characteristic.properties]) {
        
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        [[YKSLogger sharedLogger] logMessage:@"Writing without response..." withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
//        [self logMessageToDebugView:@"Writing without response..." isError:NO];
//        DLog(@"x Writing without response...");
    }
  
    //[self logMessageToDebugView:[NSString stringWithFormat:@"Wrote %@ (%lu)", data, (unsigned long)[data length]] isError:NO];
    //DLog(@"Wrote %@ (%lu)", data, (unsigned long)[data length]);
    
}

- (void)sendInfoToDelegate:(NSString *)message {
    
    if ([self.debugDelegate respondsToSelector:@selector(informationUpdated:)]) {
        [self.debugDelegate informationUpdated:message];
    }
    
}


- (void)stopAllScanActivity {
    
    [self stopScanTimer];
    
    self.internalBleEngineState = kYKSBLEEngineStateOff;
    
    [self.centralManager stopScan];
}


- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    
    if (peripheral.state == CBPeripheralStateConnected) {
        if ([peripheral isEqual:self.connectionManager.elevatorYLink]) {
            if ([self.debugDelegate respondsToSelector:@selector(connectedToDevice:)]) {
                [self.debugDelegate connectedToDevice:kDeviceElevatorYLink];
            }
        }
        
        [[YKSLogger sharedLogger] logMessage:@"Already connected."
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        return;
    }
    
    if (self.connectionManager.elevatorYLink && [peripheral isEqual:self.connectionManager.elevatorYLink]) {
        if ([self.debugDelegate respondsToSelector:@selector(elevatorYLinkUpdate:)]) {
            [self.debugDelegate elevatorYLinkUpdate:@"Connecting..."];
        }
    }
    
    [self.centralManager connectPeripheral:peripheral options:nil];
    
}

//Convenience wrapper to make sure attemptingToConnect gets called every time
-(void)connectToYMan:(YMan *)yMan {
    
    if ([self.debugDelegate respondsToSelector:@selector(informationUpdated:)]) {
        [self.debugDelegate informationUpdated:@"Connecting..."];
    }
    
    [yMan attemptingToConnect];
    
    [self connectToPeripheral:yMan.peripheral];
    
    
}


- (void)stopBLEActivity {
   
    [self stopAllScanActivity];
    
    [self stopAllTimers];
    
    [self disconnectFromAllPeripheralsAndExpireGuestAuths];

}


//NB: This should be called *before* expireAllGuestAuths
- (void)disconnectFromAllPeripheralsAndExpireGuestAuths {
    
    if ([self.debugDelegate respondsToSelector:@selector(disconnectedFromPeripheral:)]) {
        [self.debugDelegate disconnectedFromPeripheral:kDeviceYLink];
        [self.debugDelegate disconnectedFromPeripheral:kDeviceYMAN];
        [self.debugDelegate disconnectedFromPeripheral:kDeviceElevatorYLink];
    }

    [self disconnectFromAllYLinksAndExpireGuestAuths];
    
    [self disconnectFromAllYMen];
    
    [self disconnectFromElevator];
    
    [[MultiYManGAuthDispatcher sharedInstance] expireAllGuestAuths];
}
    

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (error) {
        
#ifdef DEBUG
//        AudioServicesPlayAlertSound(1057);
#endif
        
        if (error.code == 0) {
            
            [[YKSErrorReporter sharedReporter] reportErrorWithType:kBLEErrorCode0];
            
        }
        
        [[YKSLogger sharedLogger] logMessage:[NSString
                                                         stringWithFormat:@"Did Fail to Connect to Peripheral: %@\nError: %@",
                                                         peripheral, error]
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
    }
    
    YMan *yMAN = [self.connectionManager yManFromPeripheral:peripheral];
    
    if (yMAN) {
        
        // yMAN failure handling:
        
        BOOL isError = NO;
        
        if (error && error.code != 7 && error.code != 6) {
            
            [[MultiYManGAuthDispatcher sharedInstance] failedToConnectPYMan:yMAN.macAddress];
            
            // Always log these errors to the console if running off of Xcode (Debug / Dev mode)
#ifdef DEBUG
            BOOL maxRetries = [yMAN didFailOnDisconnect];
            NSString * message;
            if (maxRetries) {
                message = [NSString stringWithFormat:@"Failed %i times to connect to yMan - GIVING UP", YMAN_RECONNECT_TRIALS];
                
                [[YKSLogger sharedLogger] logMessage:message
                                                 withErrorLevel:YKSErrorLevelError
                                                        andType:YKSLogMessageTypeBLE];
            }
            else {
                message = [NSString stringWithFormat:@"Failed to connect to yMan %li times", (long)[yMAN numberOfConnectionFailures]];

                [[YKSLogger sharedLogger] logMessage:message
                                                 withErrorLevel:YKSErrorLevelError
                                                        andType:YKSLogMessageTypeBLE];
            }
#else
            // simplified debug messaging for QA and PROD
            BOOL maxRetries = [yMAN didFailOnDisconnect];
            if (maxRetries) {
                NSString * message = [NSString stringWithFormat:@"Failed to connect to yMan %i times", YMAN_RECONNECT_TRIALS];
                [[YKSLogger sharedLogger] logMessage:message
                                      withErrorLevel:YKSErrorLevelError
                                             andType:YKSLogMessageTypeBLE];
            }
            
#endif
            isError = YES;
            
        }
        
        if (isError) {
            if ([yMAN shouldRetryConnection]) {
                
                [self connectToYMan:yMAN];
            }
        }
    }
    
}


- (void)subscribeToCharacteristic:(CBCharacteristic *)characteristic onPeripheral:(CBPeripheral *)peripheral {
    
    
    if (!characteristic) {
        
        [[YKSLogger sharedLogger] logMessage:@"No characteristic discovered"
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        //DLog(@"No characteristic discovered");
        return;
    }
    
    if ([self isIndicateEnabled:characteristic.properties]|| [self isNotifyEnabled:characteristic.properties]) {
        
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
    } else {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"The characteristic %@ doesn't support notify or indicate", characteristic]
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        //DLog(@"The characteristic %@ doesn't support notify or indicate", characteristic);
        return;
    }
    
}

#pragma mark - CBCharacteristicProperties convenience methods

- (NSDictionary *)dictionaryFromProperties:(CBCharacteristicProperties)properties {
    
    NSMutableDictionary * propertiesDict = [NSMutableDictionary dictionary];
    
    if ([self isReadEnabled:properties]) {
        propertiesDict[@"Read"] = @YES;
    }
    if ([self isWriteWithoutResponseEnabled:properties]) {
        propertiesDict[@"Write without response"] = @YES;
    }
    
    if ([self isWriteEnabled:properties]) {
        propertiesDict[@"Write"] = @YES;
    }
    
    if ([self isNotifyEnabled:properties])
        propertiesDict[@"Notify"] = @YES;
    
    if ([self isIndicateEnabled:properties])
        propertiesDict[@"Indicate"] = @YES;
    
    return [NSDictionary dictionaryWithDictionary:propertiesDict];
}


- (BOOL)isIndicateEnabled:(CBCharacteristicProperties)properties {
    
    return (properties & CBCharacteristicPropertyIndicate) != 0;
    
}

-(BOOL)isNotifyEnabled:(CBCharacteristicProperties)properties {
    
    return (properties & CBCharacteristicPropertyNotify) != 0;
}

-(BOOL)isWriteEnabled:(CBCharacteristicProperties)properties {
    
    return (properties & CBCharacteristicPropertyWrite) != 0;
}

-(BOOL)isWriteWithoutResponseEnabled:(CBCharacteristicProperties)properties {
    
    return (properties & CBCharacteristicPropertyWriteWithoutResponse) != 0;
}

-(BOOL)isReadEnabled:(CBCharacteristicProperties)properties {
    
    return (properties & CBCharacteristicPropertyRead) != 0;
}


-(NSString *)propertiesDescription:(NSDictionary *)propertiesDict {
    
    NSMutableString * description = [NSMutableString stringWithString:@""];
    
    for (NSString * key in propertiesDict.keyEnumerator) {
        
        if ([propertiesDict[key]  isEqual: @YES]) {
            
            [description appendString:[NSString stringWithFormat:@"    %@\n",key]];
        }
        
    }
    
    return [NSString stringWithString:description];
    
}


@end
