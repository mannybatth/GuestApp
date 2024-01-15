//
//  ConnectionManager.h
//  Pods
//
//  Created by Roger Mabillard on 2014-11-12.
//
//

#import <Foundation/Foundation.h>
#import "YBLEManager.h"
#import "YMan.h"
#import "YikesBLEConstants.h"
#import "YKSPrimaryYMan.h"

/**
 * MSG-09 possible content
 */


@interface ConnectionManager : NSObject

@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) YBLEManager * bleManager;


@property (nonatomic, strong) CBPeripheral * elevatorYLink;
@property (nonatomic, strong) CBCharacteristic * elevatorWriteCharacteristic;

- (id)initWithBLEManager:(YBLEManager *)bleManager andQueue:(dispatch_queue_t)centralQueue;


//Adding new objects
- (GuestAuth *)addNewGuestAuthWithYMan:(YMan *)yMan andMessage:(NSData *)message;
-(void)addPrimaryYMan:(YKSPrimaryYMan *)yManModel;

//Updating (handles removing old ones)
-(void)updatePrimaryYMen:(NSSet *)newAddresses;


- (GuestAuth *)guestAuthForYLinkPeripheral:(CBPeripheral *)peripheral;
-(GuestAuth *)guestAuthForAdvertisementData:(NSDictionary *)advertisementData;
-(GuestAuth *)guestAuthForAdvUUID:(CBUUID *)advertisingUUID;

-(NSArray *)activeGuestAuths;
- (NSArray *)activeGuestAuthsForStay:(YKSStay *)stay;
- (NSArray *)activeGuestAuthsForAmenity:(YKSAmenity *)amenity;


- (CBPeripheral *)yLinkPeripheralForGuestAuth:(NSData *)guestAuth;


-(BOOL)shouldConnectToYMan:(YMan *)yMan;

-(BOOL)shouldRequestAllGuestAuths:(YMan *)yMAN;
-(NSArray *)yLinkMACAddressesForRenewRequest:(YMan *)yMAN;

/**
 * The ones combined with the trackID and base UUID
 */
- (NSArray *)yLinkAdvUUIDsToScanFor:(BOOL)shouldStartTimer;

- (NSArray *)connectedYLinks;
- (NSArray *)connectedOrConnectingYLinks;
- (NSArray *)connectedOrConnectingYMen;

- (void)didWriteToPeripheral:(CBPeripheral *)peripheral;

- (BOOL)isPeripheralARoom:(CBPeripheral *)peripheral;

-(void)startAllConnectionTimers;

-(NSSet *)allYLinks;
-(NSSet *)disconnectedYLinksWithNoActiveGuestAuths;

-(void)resetYLinksForYMan:(YMan *)yMan;


//YMan related
- (NSArray *)advertisingUUIDsToScanForPrimaryYMEN;
- (NSArray *)macAddressesForPrimaryYMENToConnect;


-(BOOL)areThereAnyActiveGuestAuthsForYMan:(YMan *)yMan;
-(BOOL)areThereAnyUnsuccesfulGuestAuthsForYMan:(YMan *)yMan;


-(NSArray *)yMenPeripheralsForConnectionRetry;

- (void)expireAllGuestAuths;

-(void)expireAllZeroTrackIDGuestAuths;

-(void)insertPlaceholderGuestAuthForYMan:(YMan *)yMan;



//Identifying yMen
-(YMan *)yManFromAdvertisingUUID:(CBUUID *)uuid;
-(YMan *)yManFromPeripheral:(CBPeripheral *)peripheral;
-(BOOL)isPeripheralAPrimaryYMAN:(CBPeripheral *)peripheral;

-(void)removePrimaryYManWithAddress:(NSData *)macAddress;

// Cycle Events
- (void)didConnectToYLinkPeripheral:(CBPeripheral *)peripheral;

//Elevator

//-(CBCharacteristic *)elevatorWriteCharacteristic;

//Cleanup
- (void)cleanUpGuestAuths;
- (void)removeAllPrimaryYMen;
- (void)removeAllGuestAuths;
- (void)removeAllYLinks;


@end
