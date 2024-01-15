//
//  YKSServicesManager.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-05-25.
//
//

#import <Foundation/Foundation.h>

@protocol YKSServicesManagerDelegate;

@interface YKSServicesManager : NSObject

@property (weak, nonatomic) id<YKSServicesManagerDelegate> delegate;

+ (instancetype)sharedManager;

/*
 Note: Each Service includes a method to check that particular service, as well as a method that gets called
 When that service becomes unavailable. We only call the "engine is missing services" delegate method
 When the service is removed, not when it becomes available.
 */

//Individual Services
-(BOOL)isReachable;
//-(BOOL)isBluetoothOn;
-(void)isBluetoothOn:(void(^)(BOOL isOn))completion;
-(BOOL)isBeaconRangingEnabled;
-(BOOL)arePushNotificationsEnabled;
-(BOOL)isBackgroundRefreshEnabled;

//All Services
//-(NSSet *)missingServices;
-(void)missingServices:(void (^)(NSSet *missingServices))completion;
//-(NSString *)missingServicesDescription;

//Handlers called from other objects to inform of change
-(void)handleBluetoothStateChanged;
-(void)handleLocationNotAuthorized;
-(void)checkForMissingServicesWithOperationError:(NSError *)error;
-(void)checkForMissingServicesOnlyIfInternetWasNotFound;
-(void)checkForMissingServices;

@end

@protocol YKSServicesManagerDelegate <NSObject>

@optional

-(void)engineIsMissingServices:(NSSet *)missingServices;

@end
