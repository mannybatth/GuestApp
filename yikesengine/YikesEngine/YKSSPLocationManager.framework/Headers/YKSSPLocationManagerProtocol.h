//
//  YKSSPLocationManagerProtocol.h
//  YKSSPLocationManager
//
//  Created by Roger Mabillard on 2016-11-05.
//  Copyright © 2016 yikes. All rights reserved.
//

#ifndef YKSSPLocationManagerProtocol_h
#define YKSSPLocationManagerProtocol_h

@protocol YKSSPLocationManagerDelegate <NSObject>

@required

- (void)notifyMissingServices;
- (void)logLocationMessage:(NSString *)message;
- (void)didEnterBeaconRegion;
- (void)didExitBeaconRegion;

@end

#endif /* YKSSPLocationManagerProtocol_h */
