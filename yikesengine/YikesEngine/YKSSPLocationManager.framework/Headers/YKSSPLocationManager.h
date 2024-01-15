//
//  YKSSPLocationManager.h
//
//  Created by Roger Mabillard on 2016-11-04.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "YKSSPLocationManagerProtocol.h"

@import YikesSharedModel;

@interface YKSSPLocationManager : NSObject <CLLocationManagerDelegate>

@property (weak, nonatomic) id<YKSSPLocationManagerDelegate> delegate;
@property (nonatomic, assign, readonly) YKSLocationState currentSPLocationState;
@property (nonatomic, strong) CLLocationManager * locationManager;
@property (nonatomic, strong) NSString *hoteliBeaconUUID;
@property (nonatomic, strong) NSString *hoteliBeaconIdentifier;


-(BOOL)isInsideYikesRegion;
+ (instancetype)sharedManager;


- (void)startMonitoringProcess;
- (void)stopMonitoringProcess;
- (void)requestState:(BOOL)forced;
- (BOOL)isAlreadyMonitoring;
- (BOOL)isAlreadyMonitoringForRegion:(CLBeaconRegion *)regionToFind;
- (BOOL)isAlreadyRangingForRegion:(CLBeaconRegion *)regionToFind;


@end
