//
//  YKSLocationManager.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-05-26.
//
//

#import "YKSLocationManager.h"
#import "YKSServicesManager.h"
#import "YikesBLEConstants.h"
#import "YKSLogger.h"
#import "YBLEManager.h" //TODO: temporary, until Yikes.m is m
#import "YikesEngineMP.h"


@interface YKSLocationManager ()


@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, assign) BOOL didRequestState;

-(void)setInsideYikesRegion:(BOOL)insideYikesRegion;

@end

@implementation YKSLocationManager {
    
    BOOL _insideYikesRegion;
    
}

+ (instancetype)sharedManager
{
    static YKSLocationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[YKSLocationManager alloc] init];
    });
    
    return _sharedManager;
}


-(instancetype)init {
    
    self = [super init];
    
    if (self) {
        
        self.locationManager = [[CLLocationManager alloc] init];
        
        [self.locationManager requestAlwaysAuthorization];
        
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        self.locationManager.delegate = self;
        
        [self initBeaconRegion];
       
        _insideYikesRegion = NO;
    }
    
    return self;
    
}

- (YKSLocationState)currentMPLocationState {
    return _insideYikesRegion ? kYKSLocationStateEnteredMPHotel : kYKSLocationStateLeftMPHotel;
}

- (void)requestState:(BOOL)forced {
    
    [self.locationManager requestStateForRegion:self.beaconRegion];
    if (forced) {
        self.didRequestState = YES;
    }
}

- (void)initBeaconRegion {
    
    if (!_beaconRegion) {
        // Create the beacon region to be monitored.
        NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:YIKES_TEST_BEACON];
        NSString *identifier = YIKES_TEST_BEACON_IDENTIFIER;
        _beaconRegion = [[CLBeaconRegion alloc]
                         initWithProximityUUID:proximityUUID
                         identifier:identifier];
        
        _beaconRegion.notifyOnEntry = YES;
        _beaconRegion.notifyOnExit = YES;
        
        _beaconRegion.notifyEntryStateOnDisplay = YES;
    }
}

- (void)startMonitoringRegion {
    
    // Set ourselves as the Location Manager delegate.
    [self.locationManager setDelegate:self];
    
    // iOS 8 location manager (iBeacon) compatibility code:
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    // Register the beacon region with the location manager.
    
    if ([CLLocationManager isRangingAvailable]) {
        
        if (![self isAlreadyMonitoringForRegion:self.beaconRegion]) {
            [self.locationManager startMonitoringForRegion:self.beaconRegion];
            [[YKSLogger sharedLogger] logMessage:@"[Location] Started monitoring for MP beacon" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
        } else {
            [self requestState:YES];
        }
    }
}

- (void)stopMonitoringRegion {
    
    [self.locationManager setDelegate:nil];
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    
    [[YKSLogger sharedLogger] logMessage:@"[Location] Stopped monitoring for MP beacon" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
}

- (void)startRangingMultiPathRegion {
    
    if (![self isAlreadyRangingForRegion:self.beaconRegion]) {
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        [[YKSLogger sharedLogger] logMessage:@"[Location] Started ranging for MP beacon" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
    }
}

- (void)stopRangingMultiPathRegion {
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    [[YKSLogger sharedLogger] logMessage:@"[Location] Stopped ranging for MP beacon" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
}

- (BOOL)isAlreadyMonitoringForRegion:(CLBeaconRegion *)regionToFind {
    
    NSSet *monitoredRegions = self.locationManager.monitoredRegions;
    
    for (CLRegion *region in monitoredRegions) {
        
        if ([region isKindOfClass:[CLBeaconRegion class]]) {
            CLBeaconRegion *mRegion = (CLBeaconRegion *)region;
            
            if ([mRegion.proximityUUID isEqual:regionToFind.proximityUUID]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isAlreadyRangingForRegion:(CLBeaconRegion *)regionToFind {
    
    NSSet *rangedRegions = self.locationManager.rangedRegions;
    
    for (CLRegion *region in rangedRegions) {
        
        if ([region isKindOfClass:[CLBeaconRegion class]]) {
            CLBeaconRegion *mRegion = (CLBeaconRegion *)region;
            
            if ([mRegion.proximityUUID isEqual:regionToFind.proximityUUID]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)engineIsMissingServices:(NSSet *)missingServices {
    
    if (![missingServices containsObject:@(kYKSBluetoothService)]) {
        
        if (self.didRequestState == NO) {
            
            [[YKSLogger sharedLogger] logMessage:@"[Location] Bluetooth is back ON. Requesting beacon state..." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
            [self requestState:YES];
        }
    }
}

#pragma mark - in yikes Region methods

//Using methods instead of property to make result of changing the value more clear


-(void)setInsideYikesRegion:(BOOL)insideYikesRegion {
    [self setInsideYikesRegion:insideYikesRegion forced:NO];
}

- (void)setInsideYikesRegion:(BOOL)insideYikesRegion forced:(BOOL)forced {
    
    //Only inform delegates / handlers if the state *changes*
    
    if (forced) {
        
        _insideYikesRegion = insideYikesRegion;
        
        if (_insideYikesRegion) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didEnterBeaconRegion)]) {
                [self.delegate didEnterBeaconRegion];
            }
            
        } else {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didExitBeaconRegion)]) {
                [self.delegate didExitBeaconRegion];
            }
        }
    }
    else {
        if (insideYikesRegion && !_insideYikesRegion) {
            
            _insideYikesRegion = insideYikesRegion;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didEnterBeaconRegion)]) {
                [self.delegate didEnterBeaconRegion];
            }
            
        } else if (!insideYikesRegion && _insideYikesRegion) {
            
            _insideYikesRegion = insideYikesRegion;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didExitBeaconRegion)]) {
                [self.delegate didExitBeaconRegion];
            }
            
        }
    }
}

-(BOOL)isInsideYikesRegion {
    
    return _insideYikesRegion;
    
}


#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"Location Manager didStartMonitoringForRegion %@", region] withErrorLevel:YKSErrorLevelInfo andType:YKSLogMessageTypeDevice];
        
        [self stopRangingMultiPathRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        [[YKSLogger sharedLogger] logMessage:@"[Location] Failed to monitor MP region." withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
        
        [self startRangingMultiPathRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        if ([beacons count] > 0) {
            
            CLBeacon *nearestExhibit = nil;
            
            for (CLBeacon *beacon in beacons) {
                if (beacon.proximity != CLProximityUnknown) {
                    nearestExhibit = beacon;
                    break;
                }
            }
            
            if (nearestExhibit == nil) {
                
                if (_insideYikesRegion) {
                    [[YKSLogger sharedLogger] logMessage:@"[Location] Exited MP beacon region [via ranging]. No beacon in proximity." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
                    [self setInsideYikesRegion:NO];
                }
                return;
            }
            
            if (!_insideYikesRegion) {
                [[YKSLogger sharedLogger] logMessage:@"[Location] Entered MP beacon region [via ranging]." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
                [self setInsideYikesRegion:YES];
                return;
            }
            
            if ([[YBLEManager sharedManager] internalBleEngineState] != kYKSBLEEngineStateOn &&
                [[YikesEngineMP sharedEngine] engineState] == kYKSEngineStateOn) {
                
                [[YKSLogger sharedLogger] logMessage:@"[Location] Entered MP beacon region [via ranging]. Forced start." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
                [self setInsideYikesRegion:YES forced:YES];
                return;
            }
            
        } else {
            
            if (_insideYikesRegion) {
                [[YKSLogger sharedLogger] logMessage:@"[Location] Exited MP beacon region [via ranging]. No beacons found." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
                [self setInsideYikesRegion:NO];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        DLog(@"rangingBeaconsDidFailForRegion %@", YIKES_TEST_BEACON_IDENTIFIER);
        DLog(@"ERROR rangingBeaconsDidFailForRegion: %@", error);
        
        [[YKSLogger sharedLogger] logMessage:@"[Location] Failed to range MP region." withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeService];
        
        [[YKSLogger sharedLogger] logMessage:@"[Location] Exited MP beacon region [via ranging]." withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
        
        [self setInsideYikesRegion:NO];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    switch (error.code) {
        case kCLErrorDenied:
            /** Fall through */
        case kCLErrorRegionMonitoringDenied:
            [[YKSServicesManager sharedManager] checkForMissingServices];
            //TODO: Post 2.0: Handle other failure points.
        default:
            break;
    }
    
    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"[Location] [MP] Did fail with error: %@", error.localizedDescription]
                          withErrorLevel:YKSErrorLevelError
                                 andType:YKSLogMessageTypeService];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        [[YKSLogger sharedLogger] logMessage:@"[Location] Did Enter yikes MP Region" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
        [self setInsideYikesRegion:YES forced:YES];
        
    }
}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        [[YKSLogger sharedLogger] logMessage:@"[Location] Did Exit yikes MP Region" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
        [self setInsideYikesRegion: NO];
        
        [self stopRangingMultiPathRegion];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
    if ([region.identifier isEqualToString:YIKES_TEST_BEACON_IDENTIFIER]) {
        
        if (state == CLRegionStateInside) {
            
            [[YKSLogger sharedLogger] logMessage:@"[Location] Did Determine state Inside for yikes MP Region" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
            [self setInsideYikesRegion:YES];
            
        }
        else if (state == CLRegionStateOutside) {
            
            [[YKSLogger sharedLogger] logMessage:@"[Location] Did Determine state Outside for yikes MP Region" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
            [self setInsideYikesRegion:NO forced:YES];
            
            [self stopRangingMultiPathRegion];
        }
        else {
            [[YKSLogger sharedLogger] logMessage:@"[Location] Did Determine UNKNOWN state for yikes region" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeBLE];
        }
        
        self.didRequestState = NO;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    [[YKSServicesManager sharedManager] handleLocationNotAuthorized];
}


//Copied but unused, for reference
- (void)readiBeaconRegionState {
    if (self.locationManager && self.beaconRegion) {
        if (self.locationManager.rangedRegions.count > 0 && [self.locationManager.rangedRegions containsObject:self.beaconRegion]) {
            [self requestState:NO];
        }
    }
}




@end
