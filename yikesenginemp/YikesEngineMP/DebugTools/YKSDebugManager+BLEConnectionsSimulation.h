//
//  YKSDebugManager+BLEConnectionsSimulation.h
//  yEngine
//
//  Created by Alexandar Dimitrov on 2015-09-21.
//
//

#import "YKSDebugManager.h"

@interface YKSDebugManager (BLEConnectionsSimulation)

- (void)startAddingNewRSSIValues;
- (void)createFakeConnection;

@end
