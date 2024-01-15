//
//  GuestAuth.m
//  Pods
//
//  Created by Elliot Sinyor on 2014-11-10.
//
//

#import "GuestAuth.h"
#import "ConnectionManager.h"
#import "MSWeakTimer.h"
#import "YikesBLEConstants.h"
#import "YKSLogger.h"
#import "YKSSessionManager.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

#import <AudioToolbox/AudioToolbox.h>


@interface GuestAuth ()

@property (nonatomic, strong) MSWeakTimer * guestAuthExpirationTimer;
@property (nonatomic, strong) MSWeakTimer * zeroTrackIDExpirationTimer;
@property (nonatomic, strong) ConnectionManager * connectionManager;


@end

@implementation GuestAuth

-(instancetype)initWithYMan:(YMan *)yMan Message:(NSData *)message andConnectionManager:(ConnectionManager *)connectionManager{
    
    self = [super init];
    if (self) {
        self.connectionManager = connectionManager;
        self.yMan = yMan;
        
        BOOL extracted = [self extractValuesFromRoomAuth:message];
        
        if (!extracted) {
            
            [[YKSLogger sharedLogger] logMessage:@"Error: Could not extrat message %@ - returning nil GuestAuth to BLE Mananger"
                                             withErrorLevel:YKSErrorLevelError
                                                    andType:YKSLogMessageTypeBLE];
            
            return nil;
        }
        
        _numberOfTimesWritten = 0;
        
        //Init the yLink object with the address taken from the guest auth
        self.yLink = [[YLink alloc] initWithMacAddress:self.yLinkBLEAddress andPrimaryYMAN:yMan];
        
        [self determineAuthType];
        
        [self generateCombinedUUID];
    }
    
    return self;
    
}

-(BOOL)extractValuesFromRoomAuth:(NSData *)message {
    
    //Note: Since the field order has changed significantly with v4, the old method was placed
    //in the extractValuesFromRoomAuth_V1toV3 method. It is tested and works, so for that and the sake
    //of code clarity (ie not having many if/else branches..) code in this method handles v4 (and above in future)
    
    [[YKSLogger sharedLogger] logMessage:[NSString
                                                     stringWithFormat:@"Message received: %@ (%@ bytes)",
                                                     message, @(message.length)]
                                     withErrorLevel:YKSErrorLevelInfo
                                            andType:YKSLogMessageTypeBLE];
    
    if (message.length <= 20) { //V4 is always > 20 bytes long
        return [self extractValuesFromRoomAuth_V1toV3:message];
    }
    
    if (![self isStayTokenMessage:message]) {
        _authType = kGuestAuthTypeNotRoomAuth;
        return NO;
    }
    
    UInt8 * bytes = (UInt8 *)[message bytes];
  
    //"Magic Numbers" for byte positions and lengths are used below. (position, length) is in comment for each field.
    //Message definition here: https://yikesdev.atlassian.net/wiki/pages/viewpage.action?pageId=25690351
    
    //BLE Interface Version (1,1)
    UInt8 version = bytes[1];

    if (version < 4) {
        //Something is wrong here
        
        NSString *logMessage = [NSString
                             stringWithFormat:@"Invalid message received from yMan (%@, %@) Version should be >= 4. Message: %@",
                             self.yMan.macAddress, self.yMan.peripheral.name, message];
        
        [[YKSLogger sharedLogger] logMessage:logMessage withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
        
        
        _authType = kGuestAuthTypeNotRoomAuth;
        
        return NO;
    }
    
    //yLink BLE-A Address (2,6)
    _yLinkBLEAddress = [NSData dataWithBytes:&bytes[2] length:6];
    
    //TrackID (8,6)
    self.trackID = [NSData dataWithBytes:&bytes[8] length:6];
    
    //StayToken (14,6)
    self.stayToken = [NSData dataWithBytes:&bytes[14] length:6];
    
    //Timeout (20,1)
    self.timeoutSeconds = (UInt8)bytes[20];
    
    //Minimum Connect RSSI (21,1)
    _connectRSSIThreshold = (SInt8)bytes[21];
    
    //TrackID Refresh Seconds (>= V5 only)
    if (version >= 5) {
        self.trackIDRefreshSeconds = (UInt8)bytes[22];
    }
    
    /*
     V4 vs V5
     Since V5 includes an extra field (1 byte) at byte 22, the next two fields differ by 1 byte
     between V4 and V5
     (If things are changed further in later versions, some sort of lookup table should be used to keep things clean)
     */
    
    UInt8 roomNumberLengthIndex, roomNumberIndex;
    
    /**
        As per discussion with Richard on 2015-06-23, the version field indicates the highest capability
        Of the yMAN, *not* the actual version being passed back.
        So we also need to check what we passed in to be sure what version message we receive
    */
    if (version >= 5 && BLE_ENGINE_VERSION >= 5) {
        roomNumberLengthIndex = 23;
        roomNumberIndex = 24;
    } else { //We know it has to be V4
        roomNumberLengthIndex = 22;
        roomNumberIndex = 23;
        
    }
    
    //Room Number Length
    UInt8 roomNumberLength = (UInt8)bytes[roomNumberLengthIndex];
    if (roomNumberLength > 16 || roomNumberLength == 0) {
      
        //If it's an all-zero message the room number field will always be 0, so don't bother logging
        if (![self isAllZeroesMessage]) {
            
            NSString *message = [NSString stringWithFormat:@"No Room number returned with Guest Auth (room number length: %i)", roomNumberLength];
            
            [[YKSLogger sharedLogger] logMessage:message
                                             withErrorLevel:YKSErrorLevelInfo
                                                    andType:YKSLogMessageTypeBLE];
            
        }
        
        _roomNumber = @"";
        
        return YES;
    }
    //Room Number
    NSData * roomNumberRaw = [NSData dataWithBytes:&bytes[roomNumberIndex] length:roomNumberLength];
    NSString * roomNumber = [[NSString alloc] initWithData:roomNumberRaw encoding:NSUTF8StringEncoding];
   
    _roomNumber = roomNumber;
   
    return YES;
}

-(BOOL)extractValuesFromRoomAuth_V1toV3:(NSData *)message {
   
    
    int position = 0;
#ifdef DEBUG
    NSLog(@"Message received: %@", message);
#endif
    
    UInt8 * bytes = (UInt8 *)[message bytes];
    
    //Check that it matches the old message type
    UInt8 messageType = bytes[0];
    if (!(messageType == YMAN_ROOMAUTH_MSG_ID_V1toV3)) {
        _authType = kGuestAuthTypeNotRoomAuth;
        return YES;
    }
    
    position += 1;
    NSData * trackID = [NSData dataWithBytes:&bytes[position] length:6];
    
    self.trackID = trackID;
    
    position +=6;
    NSData * stayToken = [NSData dataWithBytes:&bytes[position] length:6];
    
    self.stayToken = stayToken;
    
    position += 6;
    NSData * timeout = [NSData dataWithBytes:&bytes[position] length:2];
    NSString *timeoutHexString = [YKSBinaryHelper hexStringFromBinary:timeout];
    
    if (timeoutHexString) {
        unsigned int timeout_seconds;
        NSScanner* scanner = [NSScanner scannerWithString:timeoutHexString];
        [scanner scanHexInt:&timeout_seconds];
        self.timeoutSeconds = timeout_seconds;
    } else {
        self.timeoutSeconds = YLINK_DEFAULT_ROOMAUTH_EXPIRATION;
    }
    
    position += 2;
   
    //For version 1, the message length is 15 bytes. There won't be any room number info, so return early
    if (message.length <= position) {
        return YES;
    }
   
    //The next byte is either room number length (v2) or RSSI threshold (v3)
    
    int8_t threshold = bytes[position];
    
    //If the threshold is 0 or positive, we take it to mean "no threshold"
    //This will also work for v2 since the room length will be > 0
    if (threshold >= 0) {
        threshold = -127;
    }
    
    _connectRSSIThreshold = threshold;
#ifdef DEBUG
    NSLog(@"threshold: %i", threshold);
#endif
    
    if (BLE_ENGINE_VERSION > 2) {
        position +=1;
    }
    
    UInt8 roomNumberLength = bytes[position];
    
    NSData * roomNumber = nil;
    
    position += 1;
    roomNumber = [NSData dataWithBytes:&bytes[position] length:roomNumberLength];
    
    //Filter out any non alphanumeric characters
    NSString * room = [[NSString alloc] initWithData:roomNumber encoding:NSUTF8StringEncoding];
    room = [room stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    
#ifdef DEBUG
    NSLog(@"Room number:whitespaceAndNewlineCharacterSet]]; %@", room);
#endif
    
    _roomNumber = room;
    
    return YES;
   
}

-(BOOL)isActive {
    
    if (![self isTimerExpired]) {
       
        return YES;
    }
    
    if (_authType == kGuestAuthTypeValid ||
        _authType == kGuestAuthTypeTrackIDZeros ||
        _authType == kGuestAuthTypeWritten) {
       
        return YES;
    }
    
    
    if (_authType == kGuestAuthTypeExpired && self.yLink.peripheral.state == CBPeripheralStateConnected) {
        
        return YES;
        
    }
   
    return NO;
    
}

-(BOOL)isTimerExpired {
  
    return !self.guestAuthExpirationTimer;
    
}


-(BOOL)isAllZeroesMessage {
    
    char zeroBytes[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    
    NSData * zeroes = [NSData dataWithBytes:zeroBytes length:6];
    
    if ([self.trackID isEqualToData:zeroes] && [self.stayToken isEqualToData:zeroes]) {
        return YES;
    } else {
        return NO;
    }
    
}

-(void)determineAuthType {
    //Create a 6-byte pattern of zeros to compare with trackID + Stay Token
    char zeroBytes[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    NSData * zeroes = [NSData dataWithBytes:zeroBytes length:6];
    
    // trackID and stayToken cannot be nil
    if ([self isAllZeroesMessage] || !self.trackID || !self.stayToken) {
        
        NSString *message = [NSString
                             stringWithFormat:@"Determined GAuthTypeAllZeros for tID %@ and sTo %@ ",
                             self.trackID, self.stayToken];
        
        [[YKSLogger sharedLogger] logMessage:message
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        _authType = kGuestAuthTypeAllZeros;
        
    } else if ([self.trackID isEqualToData:zeroes]) {
        
#ifdef DEBUG
//        AudioServicesPlayAlertSound(1020);
#endif
        NSString *message = [NSString
                             stringWithFormat:@"Determined GAuthTypeTrackIDZeros for tID %@ and sTo %@ ",
                             self.trackID, self.stayToken];
        
        [[YKSLogger sharedLogger] logMessage:message
                                         withErrorLevel:YKSErrorLevelError
                                                andType:YKSLogMessageTypeBLE];
        
        _authType = kGuestAuthTypeTrackIDZeros;
        
    } else if (![YKSSessionManager isRoomNameInStay:self.roomNumber]) {
      
        NSString * message = [NSString
                              stringWithFormat:@"Room %@ not found in any Stays from yCentral", self.roomNumber];
        
       
        [[YKSLogger sharedLogger] logMessage:message withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeAPI];
        
        _authType = kGuestAuthTypeNotExpectedRoom;
            
    } else {
        
        NSString *message = [NSString
                             stringWithFormat:@"Determined GAuthTypeValid for tID %@ and sTo %@ ",
                             self.trackID, self.stayToken];
        
        [[YKSLogger sharedLogger] logMessage:message
                                         withErrorLevel:YKSErrorLevelInfo
                                                andType:YKSLogMessageTypeBLE];
        
        _authType = kGuestAuthTypeValid;
    }
    
    
}


-(void)generateCombinedUUID {
   
    if (self.trackID == nil || self.trackID.length != 6.0) {
        _yLinkAdvertisementCombinedUUID = nil;
        return;
    }
    
    NSData * baseUUID = [YKSBinaryHelper binaryFromHexString:YLINK_ADV_SERVICE_BASE_UUID];
    
    NSMutableData * combined = [NSMutableData dataWithData:self.trackID];
    [combined appendData:baseUUID];
    
    _yLinkAdvertisementCombinedUUID = [CBUUID UUIDWithData:combined];
    
}


-(CBUUID *)combinedUUIDWithTrackID:(NSData *)trackID {
    
    if (trackID == nil || trackID.length != 6.0) {
        //DLog(@"Cannot create combined UUID, invalid stay token: %@", trackID);
        return nil;
    }
    
    NSData * baseUUID = [YKSBinaryHelper binaryFromHexString:YLINK_ADV_SERVICE_BASE_UUID];
    
    NSMutableData * combined = [NSMutableData dataWithData:trackID];
    [combined appendData:baseUUID];
    
    return [CBUUID UUIDWithData:combined];
    
}


-(BOOL)isStayTokenMessage:(NSData *)message {
    
    UInt8 * bytes = (UInt8 *)[message bytes];
    if (bytes[0] == YMAN_ROOMAUTH_MSG_ID) {
        return YES;
    } else {
        return NO;
    }
    
}


//Timer methods

-(void)startConnectionTimer {
    
    [self stopConnectionTimer];
   
    //TODO: Maybe this should call a timeout method directly in the BLE Manager? We also need to inform the ConnectionManager so maybe not.
    if (!self.connectTimer) {
        self.connectTimer = [MSWeakTimer scheduledTimerWithTimeInterval:YLINK_DISCOVERY_TIME target:self selector:@selector(connectionTimedOut) userInfo:nil repeats:NO dispatchQueue:self.connectionManager.queue];
    }
    
    
}

-(void)stopConnectionTimer {
   
    if (self.connectTimer) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
    
}

-(void)connectionTimedOut {
   
    [self stopConnectionTimer];
  
    [[YBLEManager sharedManager] yLinkConnectionTimedOut:self.roomNumber];
#ifdef DEBUG
    NSLog(@"YLINK TIMED OUT!!!!!!");
#endif
    
    //TODO: what to do here?
    // we could either 1) try again until the guest auth is expired 2) expire the guest auth so that we go back to yMan next cycle
    // currently doing 2), needs to be discussed
   
    //Something is wrong if we can't connect, go back to yMan
    _authType = kGuestAuthTypeExpired;
    
}


-(void)startGuestAuthExpirationTimer {
    
    [self stopGuestAuthExpirationTimer];
   
    NSTimeInterval timeout;
    if (!self.timeoutSeconds) {
        timeout = YLINK_DEFAULT_ROOMAUTH_EXPIRATION;
    } else {
        timeout = self.timeoutSeconds;
    }
    
    self.guestAuthExpirationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(roomAuthExpirationTimerTimedOut) userInfo:nil repeats:NO dispatchQueue:self.connectionManager.queue];
}

-(void)stopGuestAuthExpirationTimer {
    
    if (self.guestAuthExpirationTimer) {
        [self.guestAuthExpirationTimer invalidate];
        self.guestAuthExpirationTimer = nil;
    }
}

//TODO: Adapt to Multi Access
-(void)roomAuthExpirationTimerTimedOut {
    
    //[self removeYLinkAdvertisingUUIDAndResumeScanning];
   
    [self stopGuestAuthExpirationTimer];
   
    /* DELETE when transitioning to Engine
    if (self.yLink.peripheral && self.yLink.peripheral.state != CBPeripheralStateDisconnected) {
        //[self cancelPeripheralConnection:self.yLink];
        // avoid the room auth to continue in didDisconnect by nilling the yLink reference:
       self.yLink.peripheral = nil;
    }
     */
    
    
    
    
    [self stopConnectionTimer];
    
    if (_authType != kGuestAuthTypeWritten) {
       
        [[YBLEManager sharedManager] yLinkConnectionTimedOut:self.roomNumber];
        
        _authType = kGuestAuthTypeExpired;
        [[MultiYManGAuthDispatcher sharedInstance] didExpire:self.trackID pYman:self.yMan.macAddress];
        NSString *msg = [NSString stringWithFormat:@"%@ expired", self.trackID];
        
        [[YKSLogger sharedLogger] logMessage:msg
                              withErrorLevel:YKSErrorLevelError
                                     andType:YKSLogMessageTypeBLE];

    }
    
    
    
    
    //[self stopYLinkTrackIDSessionTimer];
    
    //[self logMessageToDebugView:@"TrackID Session Timed Out" isError:NO];
    
    //[self resetConditionsToWriteToYMAN];
}


-(void)startZeroTrackIDExpirationTimer {
   
    [self stopZeroTrackIDExpirationTimer];
   
    self.zeroTrackIDExpirationTimer = [MSWeakTimer scheduledTimerWithTimeInterval:YLINK_ZERO_TRACKID_PAUSE_TIME target:self selector:@selector(zeroTrackIDExpirationTimeout) userInfo:nil repeats:NO dispatchQueue:self.connectionManager.queue];
    
    
}

-(void)stopZeroTrackIDExpirationTimer {
   
    if (self.zeroTrackIDExpirationTimer) {
        [self.zeroTrackIDExpirationTimer invalidate];
        self.zeroTrackIDExpirationTimer = nil;
    }
    
}


-(void)zeroTrackIDExpirationTimeout {
   
    _authType = kGuestAuthTypeExpired;
    
}

-(BOOL)isEqual:(id)object {
  
    if (![object isKindOfClass:[GuestAuth class]]) {
        return NO;
    }
    
    GuestAuth * comparison = (GuestAuth *)object;
    if ([self.trackID isEqualToData:comparison.trackID]
        &&
        [self.yMan.macAddress isEqualToData:comparison.yMan.macAddress]
        &&
        ((!self.expirationDate && !comparison.expirationDate )|| [self.expirationDate isEqualToDate:self.expirationDate])) {
        
        return YES;
    }
    else {
        return NO;
    }
    
    
}

-(void)setWritten {
    
    _authType = kGuestAuthTypeWritten;
    
    _numberOfTimesWritten += 1;
    
}

- (void)setUnWritten {
    _authType = kGuestAuthTypeValid;
}

- (void)setExpired {
    self.expirationDate = [NSDate date];
    _authType = kGuestAuthTypeExpired;
    [self stopGuestAuthExpirationTimer];
    [self roomAuthExpirationTimerTimedOut];
    
    [self updateStayOrAmenityConnectionStatus:kYKSConnectionStatusDisconnectedFromDoor];
}


- (void)updateStayOrAmenityConnectionStatus:(YKSConnectionStatus)newStatus {
    
    if (self.stay != nil) {
        self.stay.connectionStatus = newStatus;
    } else if (self.amenityDoor != nil) {
        self.amenityDoor.connectionStatus = newStatus;
    } else {
        [[YKSLogger sharedLogger] logMessage:@"GuestAuth has no reference to stay or amenity, can't update connection status" withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeAPI];
    }
    
}

- (NSString *)description {
   
    NSString * description = [NSString stringWithFormat:@"GuestAuth\nRoom: %@ stayToken: %@ trackID %@ Times written: %li AuthType: %ld\nyMAN: %@\nyLink: %@",
                              self.roomNumber, self.stayToken, self.trackID,  (long)self.numberOfTimesWritten, (unsigned long)self.authType, self.yMan, self.yLink];

    return description;
}


@end
