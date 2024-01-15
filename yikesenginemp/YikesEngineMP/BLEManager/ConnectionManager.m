//
//  ConnectionManager.m
//  Pods
//
//  Created by Roger Mabillard on 2014-11-12.
//
//

#import "ConnectionManager.h"
#import "GuestAuth.h"
#import "YKSSessionManager.h"
#import "YKSLogger.h"

@interface ConnectionManager ()

//TODO: replace these with NSSets to avoid need for comparison before adding
@property (nonatomic, strong) NSArray * guestAuths;
@property (nonatomic, strong) NSArray * primaryYMen; 
@property (nonatomic, strong) NSSet * yLinks; //any yLink for which we've been given a guest auth by yMan

@property (nonatomic, strong) CBService * elevatorService;

@end

@implementation ConnectionManager

#pragma mark - Init

- (id)initWithBLEManager:(YBLEManager *)bleManager andQueue:(dispatch_queue_t)centralQueue {
    self = [super init];
    if (self) {
        _queue = centralQueue;
        _bleManager = bleManager;
        self.guestAuths = [NSArray array];
        self.primaryYMen = [NSArray array];
        self.yLinks = [NSSet set];
    }
    
    return self;
    
}

#pragma mark - yLink / GuestAuth related

- (BOOL)isNewGuestAuth:(GuestAuth *)guestAuth {
    BOOL isNew = YES;
    for (GuestAuth *ga in self.guestAuths) {
        if ([guestAuth isEqual:ga]) {
            isNew = NO;
            break;
        }
    }
    
    return isNew;
}

- (GuestAuth *)addNewGuestAuthWithYMan:(YMan *)yMan andMessage:(NSData *)message {
    
    GuestAuth * guestAuth = [[GuestAuth alloc] initWithYMan:yMan Message:message andConnectionManager:self];
    
    if (guestAuth == nil) {
        return nil;
    }
    
    id stayOrAmenity = [YKSSessionManager stayOrAmenityForRoomNumber:guestAuth.roomNumber];
    
    if ([stayOrAmenity class] == [YKSStay class]) {
        
        guestAuth.stay = (YKSStay *)stayOrAmenity;
        
    } else if ([stayOrAmenity class] == [YKSAmenity class]) {
        
        guestAuth.amenityDoor = (YKSAmenity *)stayOrAmenity;
        
    }
    
    if (guestAuth.authType == kGuestAuthTypeValid || guestAuth.authType == kGuestAuthTypeTrackIDZeros) {
        
        if ([self isNewGuestAuth:guestAuth]) {
            
            NSMutableArray * newAuths = [self.guestAuths mutableCopy];
            [newAuths addObject:guestAuth];
            self.guestAuths = [NSArray arrayWithArray:newAuths];
            
            if (guestAuth.authType == kGuestAuthTypeValid)  {
                [guestAuth startGuestAuthExpirationTimer]; //Start the expiration timer
            } else { //it's a zero-trackID case
                [guestAuth startZeroTrackIDExpirationTimer];
            }
          
            //Add the yLink to the set
            if (guestAuth.yLink != nil) {
                NSMutableSet * yLinks = [self.yLinks mutableCopy];
                [yLinks addObject:guestAuth.yLink];
                self.yLinks = [NSSet setWithSet:yLinks];
            }
            
            
        }
        
        
//        if (![self.guestAuths containsObject:guestAuth]) {
//            NSMutableArray * newAuths = [self.guestAuths mutableCopy];
//            [newAuths addObject:guestAuth];
//            self.guestAuths = [NSArray arrayWithArray:newAuths];
//           
//            if (guestAuth.authType == kGuestAuthTypeValid)  {
//                [guestAuth startGuestAuthExpirationTimer]; //Start the expiration timer
//            } else { //it's a zero-trackID case
//                [guestAuth startZeroTrackIDExpirationTimer];
//            }
//        }
        else {
#ifdef DEBUG
            NSLog(@"self.guestAuths %@ already contains %@", self.guestAuths, guestAuth);
#endif
        }
        
    }
    
    return guestAuth;
}


-(NSArray *)activeGuestAuths {
   
    NSMutableArray * activeGuestAuths = [NSMutableArray array];
    
    for (GuestAuth * guestAuth in self.guestAuths) {
   
        if ([guestAuth isActive]) {
            
            [activeGuestAuths addObject:guestAuth];
        }
    }
    
    return [NSArray arrayWithArray:activeGuestAuths];
    
}


//Removes expired and invalid guest auths. Keeps zero-trackID guest auths (nb: not all-zero message) to prevent going back to yMan right away.
-(void)cleanUpGuestAuths {
   
    NSMutableArray * mutableGuestAuths = [self.guestAuths mutableCopy];
    
    for (GuestAuth * guestAuth in self.guestAuths) {
        //only get rid of the guest auth if the yLink is Disconnected (not connected or connecting)
        //(Otherwise, if it’s removed immediately after writing, didDisconnect can’t know which yLink just disconnected)
        
        if (guestAuth.authType != kGuestAuthTypeValid &&
            guestAuth.authType != kGuestAuthTypeTrackIDZeros &&
            // guestAuth.authType != kGuestAuthTypeWritten &&
            guestAuth.yLink.peripheral.state == CBPeripheralStateDisconnected &&
            guestAuth.isTimerExpired) {
            
            guestAuth.yLink = nil;
            
            [mutableGuestAuths removeObject:guestAuth];
        }
    }
    
    self.guestAuths = [NSArray arrayWithArray:mutableGuestAuths];
    
}

- (NSArray *)connectedYLinks {
    NSMutableArray *connectedYL = [NSMutableArray array];
    for (GuestAuth *guestAuth in self.guestAuths) {
        if (guestAuth.yLink.peripheral.state == CBPeripheralStateConnected) {
            [connectedYL addObject:guestAuth.yLink.peripheral];
        }
    }
    
    return [NSArray arrayWithArray:connectedYL];
}

//More stringent than just connected, also includes yLinks in the process of being connected to
- (NSArray *)connectedOrConnectingYLinks {
   
    NSMutableArray * connectedOrConnecting = [NSMutableArray array];
   
    for (GuestAuth * guestAuth in self.guestAuths) {
       
        if (guestAuth.yLink.peripheral.state != CBPeripheralStateDisconnected) {
            [connectedOrConnecting addObject:guestAuth.yLink.peripheral];
        }
        
    }
    return [NSArray arrayWithArray:connectedOrConnecting];
}


- (NSArray *)connectedOrConnectingYMen {
   
    NSMutableArray * connectedOrConnecting = [NSMutableArray array];
    
    for (YMan * yMan in self.primaryYMen) {
       
        if (yMan.peripheral.state != CBPeripheralStateDisconnected) {
            [connectedOrConnecting addObject:yMan];
        }
        
    }
    
    return [NSArray arrayWithArray:connectedOrConnecting];
    
}



- (CBPeripheral *)yLinkPeripheralForGuestAuth:(NSData*)trackID {
    for (GuestAuth *ga in self.guestAuths) {
        if ([ga.trackID isEqualToData:trackID]) {
            return ga.yLink.peripheral;
        }
    }
    return nil;
}

-(BOOL)isConnectedToAnyYLinks {
    
    return [self connectedYLinks].count > 0;
    
}

- (GuestAuth *)guestAuthForYLinkPeripheral:(CBPeripheral *)peripheral {
    for (GuestAuth *guestAuth in self.guestAuths) {
        if ([guestAuth.yLink.peripheral isEqual:peripheral]) {
            return guestAuth;
        }
    }
    
    return nil;
}


-(void)startAllConnectionTimers {
    
    for (GuestAuth * guestAuth in self.guestAuths) {
        [guestAuth startConnectionTimer];
    }
    
}


//This is used when we know the advertising UUID for sure
-(GuestAuth *)guestAuthForAdvUUID:(CBUUID *)advertisingUUID {
    
    for (GuestAuth * roomAuth in self.guestAuths) {
       
        if ([advertisingUUID.UUIDString isEqualToString:roomAuth.yLinkAdvertisementCombinedUUID.UUIDString]) {
            return roomAuth;
        }
        
    }
   
    return nil;
    
}

//Used when we have the advertisement data, extracts any possible UUIDs from it and uses guestAuthForAdvUUID to return the result
-(GuestAuth *)guestAuthForAdvertisementData:(NSDictionary *)advertisementData {
    
    NSArray * UUIDs = advertisementData[@"kCBAdvDataServiceUUIDs"];
    NSArray * hashedUUIDs = advertisementData[@"kCBAdvDataHashedServiceUUIDs"]; //when peripheral app is backgrounded, this is what we ses
    
    if (UUIDs == nil && hashedUUIDs == nil) {
        return nil;
    }
    
    NSArray * allUUIDs;
    if (UUIDs == nil) {
        allUUIDs = hashedUUIDs;
    } else {
        allUUIDs = [UUIDs arrayByAddingObjectsFromArray:hashedUUIDs];
    }
    
    for (CBUUID * uuid in allUUIDs) {
       
        GuestAuth * roomAuth = [self guestAuthForAdvUUID:uuid];
        if (roomAuth != nil) {
            return roomAuth;
        }
        
    }
    
    return nil;
   
}


-(NSArray *)guestAuthsForYMan:(YMan *)yMan {
  
    NSMutableArray * guestAuths = [NSMutableArray array];
    
    for (GuestAuth * guestAuth in self.guestAuths) {
       
        if ([guestAuth.yMan isEqual:yMan]) {
           
            [guestAuths addObject:guestAuth];
            
        }
        
    }
    
    return [NSArray arrayWithArray:guestAuths];
    
}

/**
 * The ones combined with the trackID and base UUID
 * Since this is only called from scanForNecessaryDevices, it's ok to 
 * update the debug console from here. If that ever changes (ie more than 1 caller to this method)
 * then we can no longer update the debug console from here
 */
- (NSArray *)yLinkAdvUUIDsToScanFor:(BOOL)shouldStartTimer {
    
    NSMutableArray * combinedUUIDs = [NSMutableArray array];
    
    for (GuestAuth * guestAuth in self.guestAuths) {
        
        if ([self shouldScanForYLinkWithGuestAuth:guestAuth]) {
            
            [combinedUUIDs addObject:guestAuth.yLinkAdvertisementCombinedUUID];
            
            if (!guestAuth.connectTimer) {
                [[MultiYManGAuthDispatcher sharedInstance] startedScanforGA:guestAuth.trackID roomNumber:guestAuth.roomNumber pYMan:guestAuth.yMan.macAddress
                                                              RSSIThreshold:[NSNumber numberWithInteger:guestAuth.connectRSSIThreshold]
                                                                    timeout:guestAuth.timeoutSeconds];
            }
            else {
#ifdef DEBUG
                NSLog(@"Not calling the Debugger - Scan for trackID-based UUID %@ already started", guestAuth.trackID);
#endif
            }
            
            if (shouldStartTimer) {
                [guestAuth startConnectionTimer];
            }
            
            // This resets the timer every second - don't use to track GA to yLink times...
        }
        
    }
    
    return [NSArray arrayWithArray:combinedUUIDs];
    
}

-(BOOL)shouldScanForYLinkWithGuestAuth:(GuestAuth *)guestAuth {
   
    BOOL should = (guestAuth.yLinkAdvertisementCombinedUUID != nil //If there's no combined ID, don't scan
                   && (guestAuth.authType == kGuestAuthTypeValid || guestAuth.authType == kGuestAuthTypeWritten) //Only scan if the guest auth is "valid" (ie not all zeroes, expired)
                   && guestAuth.yLink.peripheral.state == CBPeripheralStateDisconnected); //only scan if the yLink is not connected or in the process of being connected
    
    return should;
    
}



//DELETE, never called
/*
- (BOOL)doesContainAnyUUIDsFrom:(NSArray *)uuids {
    
    NSArray * allCombinedUUIDs = [self yLinkAdvUUIDsToScanFor:NO];

    if (allCombinedUUIDs.count == 0) {
        return NO;
    }
    //go through yLinkAcess object, extract all
    for (CBUUID * combinedUUID in uuids) {
    
        if ([allCombinedUUIDs containsObject:combinedUUID]) {
            return YES;
        }
        
    }
    
    return NO;
    
}
*/

- (BOOL)isPeripheralARoom:(CBPeripheral *)peripheral {
    
    if ([self guestAuthForYLinkPeripheral:peripheral] != nil) {
        return YES;
    } else {
        return NO;
    }
    
    
}

- (void)didConnectToYLinkPeripheral:(CBPeripheral *)peripheral {
    
    //We still need to check if this GuestAuth is in the array
    GuestAuth * guestAuth = [self guestAuthForYLinkPeripheral:peripheral];
   
    if (guestAuth) {
        [guestAuth stopConnectionTimer];
       
        //GAD-937: Since there can be a situation where the guest app keeps trying with a bad auth, we have to
        //avoid restarting the timer until it is fixed
        //[guestAuth startGuestAuthExpirationTimer];
        
        [[MultiYManGAuthDispatcher sharedInstance] connectedGA:guestAuth.trackID pYMan:guestAuth.yMan.macAddress];
    }
}


- (void)didWriteToPeripheral:(CBPeripheral *)peripheral {
    
    GuestAuth * guestAuth = [self guestAuthForYLinkPeripheral:peripheral];
    if (guestAuth) {
        
        [guestAuth setWritten];
       
        [[MultiYManGAuthDispatcher sharedInstance] receivedWriteConfirmation:guestAuth.trackID pYMan:guestAuth.yMan.macAddress];
    }
    
    
}

-(NSSet *)allYLinks {

    return self.yLinks;
    
}


-(NSSet *)disconnectedYLinksWithNoActiveGuestAuths {
   
    NSSet * allYLinks = [self allYLinks];
   
    NSMutableSet * disconnected = [NSMutableSet set];
    
    for (YLink * yLink in allYLinks) {
      
        if (yLink.peripheral.state == CBPeripheralStateDisconnected &&
            ![self areThereAnyActiveGuestAuthsForYLink:yLink]) {
                [disconnected addObject:yLink];
        }
        
    }
    return [NSSet setWithSet:disconnected];
    
}

-(BOOL)shouldRequestAllGuestAuths:(YMan *)yMAN {
 
    if (!yMAN || [self areThereAnyActiveGuestAuthsForYMan:yMAN]) {
        return NO;
    }
    
    
    if ([self anyOpenAmenitiesOnYMAN:yMAN]) {
        
        return YES;
        
    } else {
      
        //If there are no open amenities, clear the yLinks so no renewals on them
        [self resetYLinksForYMan:yMAN];
        
        if (yMAN.isMainRoom) {
       
            return YES;
        }
        
    }
    
    return NO;
    
}


-(NSArray *)yLinkMACAddressesForRenewRequest:(YMan *)yMAN {
   
    NSSet * disconnectedAndInactive = [self disconnectedYLinksWithNoActiveGuestAuths];
  
    NSMutableArray * toRenew = [NSMutableArray array];
    for (YLink * yLink in disconnectedAndInactive) {
       
        if ([yLink.primaryYMan isEqual:yMAN]) {
          
            if (yLink.macAddress && ([self anyOpenAmenitiesOnYMAN:yMAN] || yMAN.isMainRoom)) {
                [toRenew addObject:yLink.macAddress];
            }
        }
        
    }
    
    if (toRenew.count) {
        return [NSArray arrayWithArray:toRenew];
    }
    else {
        return nil;
    }
}

//this is called when requesting all guest auths so that if any
//yLinks have been reassigned to a different yMAN we don't try to renew their guest auths.
-(void)resetYLinksForYMan:(YMan *)yMan {

    NSMutableSet * currentYLinks = [[self allYLinks] mutableCopy];
    
    for (YLink * yLink in [self yLinks]) {
       
        if (yLink.peripheral.state == CBPeripheralStateDisconnected &&
            [yLink.primaryYMan isEqual:yMan]) {
            [currentYLinks removeObject:yLink];
        }
        
    }
    
    self.yLinks = [NSSet setWithSet:currentYLinks];
    
}


//Convenience methods for Stays/Amenities

- (NSArray *)activeGuestAuthsForStay:(YKSStay *)stay {
   
    NSMutableArray * auths = [NSMutableArray array];
    
    for (GuestAuth * guestAuth in [self activeGuestAuths]) {
       
        if ([guestAuth.stay isEqual:stay]) {
            [auths addObject:guestAuth];
        }
        
    }
    
    return [NSArray arrayWithArray:auths];
    
}

- (NSArray *)activeGuestAuthsForAmenity:(YKSAmenity *)amenity {
    
    NSMutableArray * auths = [NSMutableArray array];
    
    for (GuestAuth * guestAuth in [self activeGuestAuths]) {
       
        if ([guestAuth.amenityDoor isEqual:amenity]) {
            [auths addObject:guestAuth];
        }
        
    }
   
    return [NSArray arrayWithArray:auths];
    
}






#pragma mark - yMan related

-(YMan *)yManFromAdvertisingUUID:(CBUUID *)uuid {
    
    for (YMan * yMan in self.primaryYMen) {
        
        if ([yMan.advertisingUUID isEqual:uuid]) {
            return yMan;
        }
        
    }
    
    return nil;
    
}

-(YMan *)yManFromPeripheral:(CBPeripheral *)peripheral {
    
    for (YMan * yMan in self.primaryYMen) {
        
        if ([yMan.peripheral isEqual:peripheral]) {
            return yMan;
        }
        
    }
    
    return nil;
    
}

- (BOOL)isPeripheralAPrimaryYMAN:(CBPeripheral *)peripheral {
    
    if ([self yManFromPeripheral:peripheral]) {
        return YES;
    }
    else {
        return NO;
    }
    
}

//We should almost always scan for a yMAN. Decisions as to whether to connect should be made in didDiscoverPeripheral...
-(BOOL)shouldScanForYMan:(YMan *)yMan {
    
    if (yMan == nil) {
        return NO;
    }
    
    BOOL should = (yMan.advertisingUUID != nil //This means we don't have a primary yMan to look for
                   && yMan.peripheral.state == CBPeripheralStateDisconnected) //Don't scan for it it we're connecting or already connected
    //&& ![self areThereAnyActiveGuestAuthsForYMan:yMan];
//                    && yMan.guestAuth.authType != kGuestAuthTypeValid); //Don't scan for it if we've received a valid (not nil) guest auth.
    ;
    return should;
    
}


-(BOOL)shouldConnectToYMan:(YMan *)yMan {
    
    NSArray *yLinkMacAddresses;
    
    if (![YKSSessionManager areThereCurrentStaysForYMan:yMan]) {
        [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"No current stay(s) for yMAN %@", yMan.macAddress] withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
       
        [self removePrimaryYManWithAddress:yMan.macAddress];
        
        return NO;
    }
    
    if ([self shouldRequestAllGuestAuths:yMan]) {
        return YES;
    } else if (// make sure it's not nil
               (yLinkMacAddresses = [self yLinkMACAddressesForRenewRequest:yMan]) ||
               // make sure it's not empty
               (yLinkMacAddresses.count > 0)) {
        return YES;
    }
    
#ifdef DEBUG
    NSLog(@"shouldConnectToYMan: is returning NO for yMAN %@", yMan.macAddress);
#endif
//    [[YKSLogger sharedLogger] logMessage:[NSString stringWithFormat:@"shouldConnectToYMan: is returning NO for yMAN %@", yMan.macAddress] withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
    return NO;

}


- (BOOL)anyOpenAmenitiesOnYMAN:(YMan *)yMan {
   
    NSSet * allAmenities = [YKSSessionManager allAmenities];
    
    for (YKSAmenity * amenity in allAmenities) {
       
        //If a non-elevator has been configured without a mac address, we want to be
        //on the safe side and hit the yMAN
        if (!amenity.binaryMacAddress && !amenity.isElevator) {
            return YES;
        }
      
        if ([amenity isOpenNow] && [amenity.binaryMacAddress isEqualToData:yMan.macAddress]) {
            return YES;
        }
        
    }
    
    return NO;
    
}


-(void)addPrimaryYMan:(YKSPrimaryYMan *)yManModel {

    NSData * macAddress = yManModel.binaryMacAddress;

    NSSet * addresses = [self allPrimaryYMenMACAddresses];
   
    //Only add a new yMan if it doesn't already exist
    if (![addresses containsObject:macAddress]) {
        
        YMan * newYMan = [[YMan alloc] initWithAddress:macAddress];
        newYMan.isMainRoom = yManModel.isMainRoom;
        
        self.primaryYMen = [self.primaryYMen arrayByAddingObject:newYMan];
        
    }
    
    
}

//Removes primary yman with mac address, also removes all guest auths associated with it
-(void)removePrimaryYManWithAddress:(NSData *)macAddress {
   
    YMan * yManToRemove = [[YMan alloc] initWithAddress:macAddress];
    
    NSMutableArray * currentYMen = [self.primaryYMen mutableCopy];
    
    for (YMan * yMan in self.primaryYMen) {
        if ([yMan isEqual:yManToRemove]) {
           
            [currentYMen removeObject:yManToRemove];
            [self expireAllGuestAuthsForYMan:yManToRemove];
            
        }
    }
    
    self.primaryYMen = [NSArray arrayWithArray:currentYMen];
    
}


-(void)expireAllGuestAuthsForYMan:(YMan *)yMan {
    
    for (GuestAuth * guestAuth in self.guestAuths) {

        if ([guestAuth.yMan isEqual:yMan]) {
            
            [guestAuth setExpired];
            
        }
        
    }

}


-(NSSet *)allPrimaryYMenMACAddresses {
   
    //Make a set of all the existing addresses
    NSMutableSet * addresses = [NSMutableSet set];
    
    for (YMan * yMan in self.primaryYMen) {
        [addresses addObject:yMan.macAddress];
    }
    
    return addresses;
    
}

//Removes primary ymen that have been removed, adds new ones
-(void)updatePrimaryYMen:(NSSet *)newYMen {
  
    NSMutableSet * toAdd = [NSMutableSet set];
   
    //go through new set and add addresses
    for (YKSPrimaryYMan * yManModel in newYMen) {
       
        [toAdd addObject:yManModel.binaryMacAddress];
        
    }

    NSSet * newAddresses = [NSSet setWithSet:toAdd];
    
    
    NSSet * currentAddresses = [self allPrimaryYMenMACAddresses];
    
    if ([currentAddresses isEqualToSet:newAddresses]) {
        
        //Do nothing!
        return;
    }
    
    //want to find all addresses that have been removed, ie in current set but not new:
    NSMutableSet * beenRemoved = [NSMutableSet set];
    
    for (NSData * address in currentAddresses) {
        if (![newAddresses containsObject:address]) {
            [beenRemoved addObject:address];
        }
    }
    
    //Remove primary yMan (and associated guest auths) with addresses which have been removed
    for (NSData * address in beenRemoved) {
        [self removePrimaryYManWithAddress:address];
    }
    
    
    //Add all new addresses (addPrimaryYMAn will handle not adding duplicates, so we don't deal with that here)
    for (YKSPrimaryYMan * yManModel in newYMen) {
        
        [self addPrimaryYMan:yManModel];
    }
    
}



-(NSArray *)yMenWithValidGuestAuths {
  
    NSMutableSet * yMen = [NSMutableSet set];
    
    for (GuestAuth * guestAuth in self.guestAuths) {
       
        if (guestAuth.authType == kGuestAuthTypeValid) {
            if (guestAuth.yMan != nil) {
                [yMen addObject:guestAuth.yMan];
            }
        }
        
    }
   
    return [NSArray arrayWithArray:yMen.allObjects];
    
}


//This includes guestAuths with "0 trackID" which are considered "active" in that
//we shouldn't go back to their yMan for a period of time
-(NSArray *)yMenWithActiveGuestAuths {
   
    NSMutableSet * yMen = [NSMutableSet set];
    
    
    
    for (GuestAuth * guestAuth in self.guestAuths) {
        
        if ([guestAuth isActive]) {
            
            if (guestAuth.yMan != nil) {
                [yMen addObject:guestAuth.yMan];
            }
        }
        
    }
    
    return [NSArray arrayWithArray:yMen.allObjects];
    
}

-(BOOL)areThereAnyActiveGuestAuthsForYMan:(YMan *)yMan{
    
    NSArray * yMen = [self yMenWithActiveGuestAuths];
    
//    DLog(@"self.guestAuths is:");
//    NSInteger i = 0;
//    for (GuestAuth *ga in self.guestAuths) {
//        DLog(@"GA[%li]: %@\ntype: %lu", i, ga.trackID, ga.authType);
//        i++;
//    }
    
    if ([yMen containsObject:yMan]) {
        return YES;
    } else {
        return NO;
    }
    
    
}

//if any are expired, or written and disconnected
-(BOOL)areThereAnyUnsuccesfulGuestAuthsForYMan:(YMan *)yMan {
   
    NSArray * guestAuths = [self guestAuthsForYMan:yMan];
    
    for (GuestAuth * guestAuth in guestAuths) {
      
//        BOOL writtenAndDisconnected = (guestAuth.authType == kGuestAuthTypeWritten && guestAuth.yLink.state == CBPeripheralStateDisconnected);
        BOOL expiredAndDisconnected = (guestAuth.authType == kGuestAuthTypeExpired && guestAuth.yLink.peripheral.state == CBPeripheralStateDisconnected);
       
        if (expiredAndDisconnected) { // do not include written and disconnected... || writtenAndDisconnected) {
            //DLog(@"expired+dis? %@ written+dis? %@", expiredAndDisconnected? @"YES":@"NO", writtenAndDisconnected? @"YES":@"NO");
            return YES;
        }
        
    }
    
    return NO;
    
}

-(BOOL)areThereAnyActiveGuestAuthsForYLink:(YLink *)yLink {
   
    for (GuestAuth * guestAuth in self.guestAuths) {
       
        if ([guestAuth isActive] && [guestAuth.yLink isEqual:yLink]) {
            return YES;
        }
        
    }
    
    return NO;
    
    
}



//Not currently used, relies on being logged out
-(void)insertPlaceholderGuestAuthForYMan:(YMan *)yMan {
 
    //09 00 00 71 7e f4 e2 18 9f 21 4a ca 93 00 0f
    char messageBytes[] = {0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0xFF};
    NSData * message = [NSData dataWithBytes:messageBytes length:15];
   
    [self addNewGuestAuthWithYMan:yMan andMessage:message];
    
}


//When the stay info is updated, expire all "paused" zero-trackID guest auths so that
//we go back to their yMen.
-(void)expireAllZeroTrackIDGuestAuths {
   
    for (GuestAuth * guestAuth in self.guestAuths) {
        
        if (guestAuth.authType == kGuestAuthTypeTrackIDZeros) {
            
            [guestAuth stopZeroTrackIDExpirationTimer];
            [guestAuth zeroTrackIDExpirationTimeout]; //Sets authtype to expired, will be cleaned up next cycle
            
        }
        
    }
    
}

- (void)expireAllGuestAuths {
    for (GuestAuth * guestAuth in self.guestAuths) {
        [guestAuth setExpired];
    }
}


//Used by both advertisingUUIDs... + macAddresses... methods.
- (NSArray *)primaryYMenToScanFor {
   
    NSMutableArray * yMen = [NSMutableArray array];
    
    for (YMan * yMan in self.primaryYMen) {
        
        if ([self shouldScanForYMan:yMan]) {
            
            [yMen addObject:yMan];
            
        }
    }
   
    return [NSArray arrayWithArray:yMen];
    
}


//NOTE: now we scan for all primary yMen, and in didDiscoverPeripheral we determine whether or not to connect
//This was changed to allow for reliable background operation.
- (NSArray *)advertisingUUIDsToScanForPrimaryYMEN {
   
    NSMutableArray * uuids = [NSMutableArray array];
  
    for (YMan * yMan in [self primaryYMenToScanFor]) {
        
            [uuids addObject:yMan.advertisingUUID];
        
    }
    
    return [NSArray arrayWithArray:uuids];
    
}

//NB: this is not the same as the advertisingUUIDs... method. This only includes yMen we will connect to, not
//just ignore the advertisement to "stay alive"
- (NSArray *)macAddressesForPrimaryYMENToConnect {
   
    NSMutableArray * macAddresses = [NSMutableArray array];
    
    for (YMan * yMan in [self primaryYMenToScanFor]) {
       
        if ([self shouldConnectToYMan:yMan]) {
            [macAddresses addObject:yMan.macAddress];
        }
    }
    
    return [NSArray arrayWithArray:macAddresses];
    
}




//Retry methods

-(NSArray *)yMenPeripheralsForConnectionRetry {
  
    NSMutableArray * toRetry = [NSMutableArray array];
    
    for (YMan * yMan in self.primaryYMen) {
        
        if ([yMan shouldRetryConnection]) {
            [toRetry addObject:yMan];
        }
        
    }
    
    return [NSArray arrayWithArray:toRetry];
}



#pragma mark - Elevator Related

-(BOOL)isDiscoveredServiceElevator:(CBService *)discovered {
    
    
    return NO;
}


#pragma mark - Cleanup

-(void)removeAllPrimaryYMen {
    
    self.primaryYMen = [NSArray array];
    
}

-(void)removeAllGuestAuths {
    
    self.guestAuths = [NSArray array];
    
}

- (void)removeAllYLinks {
    
    self.yLinks = [NSSet set];
    
}



@end
