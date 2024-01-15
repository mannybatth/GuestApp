//
//  YKSLocationManager.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-05-26.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@import YikesSharedModel;

@protocol YKSLocationManagerDelegate;

@interface YKSLocationManager : NSObject <CLLocationManagerDelegate>

@property (weak, nonatomic) id<YKSLocationManagerDelegate> delegate;
@property (nonatomic, assign, readonly) YKSLocationState currentMPLocationState;
@property (nonatomic, strong) CLLocationManager * locationManager;

-(BOOL)isInsideYikesRegion;
+ (instancetype)sharedManager;

- (void)startMonitoringRegion;
- (void)stopMonitoringRegion;
- (void)requestState:(BOOL)forced;

@end

@protocol YKSLocationManagerDelegate <NSObject>

@required

- (void)didEnterBeaconRegion;
- (void)didExitBeaconRegion;

@end
