//
//  YKSRSSIHistogramViewController.h
//  YikesEnginePod
//
//  Created by royksopp on 2015-09-01.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSRSSIHistogramViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *rssiValuesArray;
@property (strong, nonatomic) NSNumber *rssiThresholdValue;
@property (strong, nonatomic) NSData *yManMacAddress;
@property (strong, nonatomic) NSData *trackId;
@property (strong, nonatomic) NSDate *yLinkStartTime;
@property (strong, nonatomic) NSMutableArray *connectionsState;
@property (strong, nonatomic) NSString *roomNumber;
@property (strong, nonatomic) NSMutableArray *yLinkKnownStates;
@property (assign, atomic) NSTimeInterval totalTimeInterval;


@end
