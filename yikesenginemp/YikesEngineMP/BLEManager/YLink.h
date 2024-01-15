//
//  YLink.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-31.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class YMan;

@interface YLink : NSObject

@property (nonatomic, readonly) YMan * primaryYMan;

@property (nonatomic, strong) CBPeripheral * peripheral;
@property (nonatomic, readonly) NSData * macAddress;

-(instancetype)initWithMacAddress:(NSData *)address andPrimaryYMAN:(YMan *)primaryYMAN;

@end
