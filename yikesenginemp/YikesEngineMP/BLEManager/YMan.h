//
//  YMan.h
//  Pods
//
//  Created by Elliot Sinyor on 2014-11-25.
//
//

#import <Foundation/Foundation.h>
#import "YBLEManager.h"
#import "GuestAuth.h"

@interface YMan : NSObject

-(instancetype)initWithAddress:(NSData *)macAddress;
-(void)setAdvertisingUUIDWithMACAddress:(NSData *)macAddress;

-(void)resetDisconnectFail;
-(BOOL)shouldRetryConnection;
- (NSInteger)numberOfConnectionFailures;

//Life Cycle Events
-(void)attemptingToConnect;
-(void)didConnectToYMan;
-(void)didDisconnectFromYMan;
-(BOOL)didFailOnDisconnect;

@property (nonatomic, strong) CBPeripheral * peripheral;
@property (nonatomic, strong) CBCharacteristic * characteristic;
@property (nonatomic, readonly) CBUUID * advertisingUUID;
@property (nonatomic, readonly) NSData * macAddress;

/**
 * @desc: Set this to YES to avoid scanning for this yMAN until it is set back to NO
 * @note: This should only be set if the yMAN behaves unexpectedly and for a very short period - it should also be reported to Astinus
 */
@property (nonatomic, assign) BOOL blackListed;

@property (nonatomic, assign) BOOL isMainRoom;

@end
