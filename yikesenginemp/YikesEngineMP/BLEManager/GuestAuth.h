//
//  GuestAuth.h
//  Pods
//
//  Created by Elliot Sinyor on 2014-11-10.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@import MSWeakTimer;
#import "YLink.h"
#import "YKSStay.h"
#import "YKSAmenity.h"

@class YMan;
@class ConnectionManager;

typedef NS_ENUM(NSUInteger, YLinkAuthType) {
    kGuestAuthTypeAllZeros,
    kGuestAuthTypeTrackIDZeros,
    kGuestAuthTypeValid,
    kGuestAuthTypeWritten,
    kGuestAuthTypeExpired,
    kGuestAuthTypeNotExpectedRoom,
    kGuestAuthTypeNotRoomAuth
};

@interface GuestAuth : NSObject

@property (nonatomic, strong) NSData * stayToken;
@property (nonatomic, strong) NSData * trackID;
@property (nonatomic, assign) NSTimeInterval timeoutSeconds;
@property (nonatomic, assign) NSTimeInterval trackIDRefreshSeconds;
@property (nonatomic, strong) MSWeakTimer * connectTimer;

@property (nonatomic, strong) NSDate * expirationDate;

@property (nonatomic, strong) CBPeripheral * yLinkPeripheral;
@property (nonatomic, strong) YLink * yLink;

@property (nonatomic, strong) YMan * yMan;
@property (nonatomic, assign) BOOL receivedWriteConfirmationFromYLink;

@property (nonatomic, readonly) YLinkAuthType authType;

@property (nonatomic, readonly) NSData * yLinkBLEAddress;

@property (nonatomic, readonly) NSString * roomNumber;

@property (nonatomic, readonly) NSInteger numberOfTimesWritten;

@property (nonatomic, strong, readonly) CBUUID * yLinkAdvertisementCombinedUUID;

//TODO: Add the trackID Session Timer
@property (nonatomic, strong) MSWeakTimer * yLinkTrackIDSessionTimer;

@property (nonatomic, readonly) NSInteger connectRSSIThreshold;

@property (nonatomic, strong) YKSStay * stay;
@property (nonatomic, strong) YKSAmenity * amenityDoor;


-(BOOL)isTimerExpired;

-(BOOL)isActive;


-(instancetype)initWithYMan:(YMan *)yMan Message:(NSData *)message andConnectionManager:(ConnectionManager *)connectionManager;
-(BOOL)extractValuesFromRoomAuth:(NSData *)message;


-(void)startGuestAuthExpirationTimer;
-(void)stopGuestAuthExpirationTimer;


-(void)startConnectionTimer;
-(void)stopConnectionTimer;


-(void)startZeroTrackIDExpirationTimer;
-(void)stopZeroTrackIDExpirationTimer;
-(void)zeroTrackIDExpirationTimeout;

-(void)setWritten;
- (void)setUnWritten;

- (void)setExpired;

- (void)updateStayOrAmenityConnectionStatus:(YKSConnectionStatus)newStatus;



@end
