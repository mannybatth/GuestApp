//
//  YMotionManager.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-01-30.
//
//

#import "YMotionManager.h"
#import <CoreMotion/CoreMotion.h>
#import <math.h>
#import "YikesBLEConstants.h"

#import "MultiYManGAuthDispatcher.h"


@interface YMotionManager ()

@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, strong) CMMotionActivityManager * activityManager; //For iPhone 5S+ 

@property (nonatomic, assign) CMAcceleration previousAcceleration;
@property (nonatomic, assign) NSInteger sameAccelerationCount;

@property (nonatomic, assign) double threshold;

@property (nonatomic, strong) NSOperationQueue * updateQueue;


@end

@implementation YMotionManager


+ (instancetype)sharedManager {
    
    static YMotionManager *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[YMotionManager alloc] init];
        [_sharedInstance initCoreMotion];
    });
    
    return _sharedInstance;
}


-(void)initCoreMotion {
    
    self.motionManager = [[CMMotionManager alloc] init];
    
    self.updateQueue = [[NSOperationQueue alloc] init];
    self.updateQueue.maxConcurrentOperationCount = 1;
 
    //Init previous acceleration
    CMAcceleration previous;
    previous.x = 0;
    previous.y = 0;
    previous.z = 0;
    
    self.sameAccelerationCount = 0;
    
    self.previousAcceleration = previous;
    
    self.threshold = INACTIVITY_SENSITIVITY;
    
    [self setStationary:NO];
    
    [self startAccelerometerUpdatesWithInterval:1.0];

}


-(void)startAccelerometerUpdatesWithInterval:(NSInteger)interval {
    
    self.motionManager.accelerometerUpdateInterval = interval;
   
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager startAccelerometerUpdatesToQueue:self.updateQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        
        [self handleAcceleration:accelerometerData withError:error];
        
    }];
    
    
}


-(void)handleAcceleration:(CMAccelerometerData *)accelerometerData withError:(NSError *)error {
  
    double diffX = accelerometerData.acceleration.x - self.previousAcceleration.x;
    double diffY = accelerometerData.acceleration.y - self.previousAcceleration.y;
    double diffZ = accelerometerData.acceleration.z - self.previousAcceleration.z;
    
    if (fabs(diffX) > self.threshold || fabs(diffY) > self.threshold || fabs(diffZ) > self.threshold) {
        
        self.sameAccelerationCount = 0;
        [self setStationary:NO];
        
    } else {
       
        self.sameAccelerationCount += 1;
        
    }
   
    
    if (self.sameAccelerationCount > INACTIVITY_TIMEOUT) {
        
        [self setStationary:YES];
        
    }
    
    self.previousAcceleration = accelerometerData.acceleration;
    
}


-(void)setStationary:(BOOL)stationary {
    
    if (stationary && !_isStationary) {
        [self didBecomeStationary];
    } else if (!stationary && _isStationary) {
        [self didBecomeActive];
    }
   
    _isStationary = stationary;
    
}

//Delegate calling convenience methods
-(void)didBecomeStationary {
    
    [self startAccelerometerUpdatesWithInterval:2.0];
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceBecameStationary)]) {
        [self.delegate deviceBecameStationary];
    }
    
}

-(void)didBecomeActive {
    
    [self startAccelerometerUpdatesWithInterval:1.0];
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceBecameActive)]) {
        [self.delegate deviceBecameActive];
    }
    
}



@end
