//
//  YMotionManager.h
//  Pods
//
//  Created by Elliot Sinyor on 2015-01-30.
//
//

#import <Foundation/Foundation.h>

//Note: These will be called from a background queue. If the delegate needs to do something on the main queue/thread, it needs
//to handle it
@protocol YMotionManagerDelegate <NSObject>

-(void)deviceBecameStationary;
-(void)deviceBecameActive;

@end

@interface YMotionManager : NSObject

+ (instancetype)sharedManager;

@property (readonly, assign) BOOL isStationary;

@property (weak) id<YMotionManagerDelegate> delegate;

@end
