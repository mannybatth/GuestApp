//
//  YBLEManager.h
//  yadminlab
//
//  Created by Elliot on 2/6/2014.
//  Copyright (c) 2014 Yamm Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "UserStay.h"
@import MSWeakTimer;

#import "MultiYManGAuthDispatcher.h"

#import "GuestAuth.h"

#ifndef __YKS_ERR_CALLBACK_BLOCK__
#define __YKS_ERR_CALLBACK_BLOCK__
typedef void (^CompletedWithError)(NSError* err);
#endif

@protocol YBLEManagerDebugDelegate;
@protocol YKSBLEManagerGuestEventDelegate;
@protocol YLGuestInfoDelegate;
@protocol YKSBLEProximityStateDelegate;
@protocol YKSBLEDataDelegate;
@protocol YKSAstinusLoggerDelegate;


typedef NS_ENUM(NSUInteger, ProximityState) {
    kProximityStateOutside, // kYKSEventLeftHotel
    kProximityStateInside,  // kYKSEventEnteredHotel
    kProximityStateYMAN,    // kYKSEventConnectingToDoor
    kProximityStateYLink    // kYKSEventConnectedToDoor
};

typedef NS_ENUM(NSUInteger, yksBLEKitState) {
    yksBluetoothRequirementNotFound,
    yksBluetoothRequirementFound,
    
    yksLocationServicesRequirementNotFound,
    yksLocationServicesRequirementFound,
    
    yksBackgroundAppRefreshRequirementNotFound,
    yksBackgroundAppRefreshRequirementFound
};


typedef NS_ENUM(NSUInteger, PLRoomAuth_Modes) {
    // start with default mode (0):
    PLRoomAuth_Mode_Normal,
    PLRoomAuth_Mode_BadAuth_13bytes_Random_TrackID,
    PLRoomAuth_Mode_BadAuth_13bytes_Random_StayToken,
    PLRoomAuth_Mode_BadAuth_13bytes_Random_Both,
    PLRoomAuth_Mode_BadAuth_13bytes_All0Message,
    PLRoomAuth_Mode_BadAuth_21bytes_Random_TrackID,
    PLRoomAuth_Mode_BadAuth_21bytes_Random_StayToken,
    PLRoomAuth_Mode_BadAuth_21bytes_Random_Both,
    PLRoomAuth_Mode_BadAuth_21bytes_All0Message,
    PLRoomAuth_Mode_BadAuth_21bytes_AllRandomMessage
};

@interface YBLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) BOOL showDebugNotifications;

@property (nonatomic, assign) BOOL shouldRunInBackground;

@property (nonatomic, assign) NSUInteger currentPLRoomAuthMode;
@property (nonatomic, assign) YKSBLEEngineState internalBleEngineState;

@property (nonatomic, weak) id<YBLEManagerDebugDelegate> debugDelegate;
@property (nonatomic, weak) id<YKSBLEManagerGuestEventDelegate> guestEventDelegate;
@property (nonatomic, weak) id<YKSBLEProximityStateDelegate> proximityStateDelegate;
@property (nonatomic, weak) id<YKSBLEDataDelegate> dataDelegate;
@property (nonatomic, weak) id<YKSAstinusLoggerDelegate> astinusLoggerDelegate;


/**
 * This delegate handles all data related requests and needs from the BLE Kit
 */
//@property (nonatomic, weak) id<YKSBLEDataDelegate> bleDataDelegate;

@property (nonatomic, strong) CBUUID * yMANServiceUUID;
@property (nonatomic, strong) CBUUID * yLinkServiceUUID;

@property (nonatomic, strong) NSString * yPhoneID;

@property (nonatomic, strong) CBUUID * messageCharacteristicUUID;

@property (nonatomic, assign) BOOL scanForElevator;

@property (nonatomic, assign) BOOL isAstinusLoggerEnabled;
@property (nonatomic, assign) float elevatorRSSIThreshold;
@property (nonatomic, assign) BOOL isBluetoothPoweredOn;


#pragma mark - Class Methods

+ (YBLEManager *)sharedManager;

+ (YBLEManager *)sharedManagerWithUserStay:(id)stay;

-(NSString *)bleEngineVersion;

+ (NSDictionary *)plRoomAuth_Modes_Dictionary;

#pragma mark - Instance Methods

- (id) initWithDelegate:(id<YBLEManagerDebugDelegate>)delegate;

- (void)fireDebugLocalNotification:(NSString *)message;
- (void)fireLocalNotification:(NSString *)message;

- (void)setUserStayTo:(id)theStay;

-(void)stopBLEActivity;
-(void)connectToPeripheral:(CBPeripheral *)peripheral;

-(void)writeValue:(NSData *)data toCharacteristic:(CBCharacteristic *)characteristic onPeripheral:(CBPeripheral *)peripheral;

-(void)disconnectFromAllYLinksAndExpireGuestAuths;
-(void)disconnectFromAllPeripheralsAndExpireGuestAuths;
-(void)stopAllTimers;

- (void)handleLogin;
- (void)handleLogout;

- (void)handleEnteredRegion;
- (void)handleExitedRegion;

-(void)handleUserInfoUpdatedWithRemovedStays:(NSSet *)removedStays andRemovedAmenities:(NSSet *)removedAmenities withNewRoomAssigned:(BOOL)isNewRoomAssigned;


- (void)handleDeviceBecameActive;
- (void)handleDeviceBecameStationary;


//Backwards compatibility
-(BOOL)isInsideYikesRegion;

-(BOOL)isBluetoothEnabled;

-(void)beginScanningForYikesHardware;

//For use in override
/**
 * Use to override the connection in the debug console (should be restricted / hidden)
 */
- (void)disconnectFromyLinkWithTrackID:(NSData *)guestAuth;

-(void)overrideYLinkTimeout;
- (void)overrideElevatorYLinkTimeout;

//For other objects that need a reference to the serial queue
-(dispatch_queue_t)serialQueue;

#pragma mark CentralManager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

#pragma mark CBPeripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error;
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

#pragma mark -

-(void)yManConnectionTimedOut:(MSWeakTimer *)timer;
-(void)yManDisconnectTimedOut:(MSWeakTimer *)timer;
- (void)yLinkConnectionTimedOut:(NSString *)roomName;


@property (nonatomic, readonly) MultiYManGAuthDispatcher * reporter;

@end


#pragma mark YBLEManagerDelegate

@protocol YBLEManagerDebugDelegate <NSObject>

@optional
-(void)connectedToDevice:(NSString *)deviceDescription;
- (void)informationUpdated:(NSString *)description;
- (void)yLinkUpdate:(NSString *)update;
- (void)elevatorYLinkUpdate:(NSString *)update;
-(void)disconnectedFromPeripheral:(NSString *)description;
-(void)scanningForDevice:(NSString *)description;
-(void)foundYMEN:(NSString *)description;

@end

#pragma mark YKSBLEManagerGuestEventDelegate

@protocol YKSBLEManagerGuestEventDelegate <NSObject>

@optional

- (void)receivedAuthorization:(NSString *)roomNumber;
- (void)connectingToDoor:(NSString *)roomNumber;
- (void)connectedToDoor:(NSString *)roomNumber;
- (void)disconnectedFromDoor:(NSString *)roomNumber;

@end


#pragma mark Proximity State Delegate

@protocol YKSBLEProximityStateDelegate <NSObject>

-(void)yikesLocationStateChanged:(ProximityState)newState;

@end

@protocol YKSBLEDataDelegate <NSObject>

@required
- (void)updateStayInfo;

@optional
-(void)onBLEKitStateChange:(yksBLEKitState)state;

@end;

@protocol YKSAstinusLoggerDelegate <NSObject>

@required
- (void)didReceiveLogMessage:(NSString*)message;

@end;
