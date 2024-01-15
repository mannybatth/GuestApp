//
//  YMan.m
//  Pods
//
//  Created by Elliot Sinyor on 2014-11-25.
//
//

#import "YMan.h"

#import "YikesBLEConstants.h"
#import "YKSLogger.h"

@interface YMan ()

@property (strong, nonatomic) MSWeakTimer * connectTimer;
@property (strong, nonatomic) MSWeakTimer * disconnectTimer;
@property (weak, nonatomic) YBLEManager * bleManager;
@property (assign, nonatomic) NSInteger failedConnections;

@end


@implementation YMan

-(instancetype)initWithAddress:(NSData *)macAddress {
   
    self = [super init];
    if (self) {
        
        [self setAdvertisingUUIDWithMACAddress:macAddress];
        _macAddress = macAddress;
        _bleManager = [YBLEManager sharedManager];
        self.failedConnections = 0;
        
    }
    return self;
    
}

-(void)setAdvertisingUUIDWithMACAddress:(NSData *)macAddress {
   
    //TODO: concatenate the two parts into a mac address
    
    CBUUID * defaultUUID = [CBUUID UUIDWithString:YMAN_SERVICE_UUID];
    
    if (macAddress == nil || macAddress.length < 6) {
        
        DLog(@"YMan init: nil address given, setting default UUID: %@", defaultUUID);
        _advertisingUUID = defaultUUID;
    }
    else {
        
        NSData * baseUUID = [defaultUUID data];
     
        NSData * truncated = [NSData dataWithBytes:baseUUID.bytes length:10]; //chop off the lowest order 6 bytes
   
        NSMutableData * combined = [NSMutableData dataWithData:truncated];
        
        [combined appendBytes:macAddress.bytes length:6];
   
        CBUUID * combinedUUID = [CBUUID UUIDWithData:combined];
    
        _advertisingUUID = combinedUUID;
        
    }
    
}

//Life Cycle events. Used to stop and start timers. Might get moved to Connection Manager if other
//things need to happen when these do

-(void)attemptingToConnect {
   
    [self startConnectTimer];
    
}

-(void)didConnectToYMan {
   
    [self stopConnectTimer];
    [self startDisconnectTimer];
    
}

-(void)didDisconnectFromYMan {
   
    [self stopDisconnectTimer];
    
}

- (NSInteger)numberOfConnectionFailures {
    return self.failedConnections;
}

//Returns yes if it hits the max # of trials
-(BOOL)didFailOnDisconnect {
   
    self.failedConnections += 1;
    
    if (self.failedConnections >= YMAN_RECONNECT_TRIALS) {
    
        [self resetDisconnectFail];
        return YES;
    } else {
        return NO;
    }
    
}

-(void)resetDisconnectFail {
    self.failedConnections = 0;
}

-(BOOL)shouldRetryConnection {
    
    // May 4th, 2015: Added !self.blackListed - If the yMAN is blacklisted, it should pause the retry procedure:
    if (self.failedConnections > 0 && !self.blackListed) {
        return YES;
    } else {
        
#ifdef DEBUG
        if (self.blackListed) {
            NSString *msg = [NSString stringWithFormat:@"WARNING: yMAN is blackListed, not retrying the connection: %@", self.macAddress];

            // Error
            [[YKSLogger sharedLogger] logMessage:msg withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeBLE];
        }
#endif
        
        return NO;
    }
    
}


//Timer methods

-(void)startConnectTimer {
   
    [self stopConnectTimer];
    self.connectTimer = [MSWeakTimer scheduledTimerWithTimeInterval:YMAN_CONNECTION_ATTEMPT_TIMEOUT
                                                                target:self.bleManager
                                                              selector:@selector(yManConnectionTimedOut:)
                                                              userInfo:self
                                                              repeats:NO dispatchQueue:self.bleManager.serialQueue];
    
}

-(void)stopConnectTimer {
   
    if (self.connectTimer) {
        [self.connectTimer invalidate];
    }
    self.connectTimer = nil;
    
}


-(void)startDisconnectTimer {
   
    [self stopDisconnectTimer];
    self.disconnectTimer = [MSWeakTimer scheduledTimerWithTimeInterval:YMAN_DISCONNECT_TIMEOUT target:self.bleManager selector:@selector(yManDisconnectTimedOut:) userInfo:self repeats:NO dispatchQueue:self.bleManager.serialQueue];
    
}

-(void)stopDisconnectTimer {
   
    if (self.disconnectTimer) {
        [self.disconnectTimer invalidate];
    }
    self.disconnectTimer = nil;
}


//Use the MAC address to determine if two yMan objects are equal
-(BOOL)isEqual:(id)object {
    
    if (![object isKindOfClass:[YMan class]]) {
        return NO;
    }
    
    YMan * comparison = (YMan *)object;
    if ([self.macAddress isEqual:comparison.macAddress]) {
        return YES;
    } else {
        return NO;
    }
    
    
}

-(NSUInteger)hash {
    
    return [self.macAddress hash];
    
}


- (NSString *)description {

    NSString * description = [NSString stringWithFormat:@"mac address: %@", self.macAddress];
    
    return description;
}

@end
