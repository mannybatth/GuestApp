//
//  YKSRSSIHistogramViewController.m
//  YikesEnginePod
//
//  Created by royksopp on 2015-09-01.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSRSSIHistogramViewController.h"
#import "PNChart.h"
#import "Colours.h"
#import "BLETriangleConnection.h"
#import "SDiPhoneVersion.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

@interface YKSRSSIHistogramViewController ()

@property (nonatomic) PNBarChart *barChart;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *barChartViewHolder;

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *yLinkStartTimeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *yManMacAddressLabel;

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *trackIdLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *roomNumberLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *statusLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *rssiTextLegendLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiThresholdLabel;

@end

@implementation YKSRSSIHistogramViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.roomNumberLabel.text = self.roomNumber;
    self.yManMacAddressLabel.text = [NSString stringWithFormat:@"yMan   : %@", [YKSBinaryHelper hexStringFromBinary:self.yManMacAddress]];
    
    self.trackIdLabel.text = [NSString stringWithFormat:@"Track ID: %@", [YKSBinaryHelper hexStringFromBinary:self.trackId]];
    
    self.rssiThresholdLabel.text = [NSString stringWithFormat:@"RSSI threshold: %d", self.rssiThresholdValue.intValue];
    
    NSDateFormatter *formatter = [[YKSDateHelper sharedInstance] timeOnlyHHmmssDateFormatter];
    self.yLinkStartTimeLabel.text = [formatter stringFromDate:self.yLinkStartTime];
    
    NSMutableArray *rssiValuesStrings = [NSMutableArray array];
    NSMutableArray *rssiAbsoluteValuesNumbers = [NSMutableArray array];
    NSMutableArray *strokeColours = [NSMutableArray array];
    
    BOOL shouldAddBarChart = NO;
    
    // RSSI value will be absulute values (all positive)
    // Initial values
    int minValue = 127;
    int maxValue = 0;

    
    // For testing RSSI = 127 bad reading
//    NSMutableArray *array = [NSMutableArray array];
//    [array addObject:@127];
//    [array addObjectsFromArray:self.rssiValuesArray];
//    self.rssiValuesArray = array;
    
    if (self.rssiValuesArray) {
        if ([self.rssiValuesArray count]) {
            
            shouldAddBarChart = YES;
            
            for (NSNumber *oneRSSIValue in self.rssiValuesArray) {
                NSString* stringRSSIValue = [NSString stringWithFormat:@"%d", oneRSSIValue.intValue];
                
                [rssiValuesStrings addObject:stringRSSIValue];
                
                int intRSSIValue = oneRSSIValue.intValue;
                
                if (intRSSIValue < 0) {
                    intRSSIValue *= (-1);
                    [strokeColours addObject:[UIColor blueberryColor]];
                }
                else {
                    // RSSI should be 127: bar reading
                    [strokeColours addObject:[UIColor redColor]];
                }
                
                // Taking min and max values
                if (intRSSIValue < minValue) {
                    minValue = intRSSIValue;
                }
                
                if (intRSSIValue > maxValue) {
                    maxValue = intRSSIValue;
                }
                
                [rssiAbsoluteValuesNumbers addObject:[NSNumber numberWithInt:intRSSIValue]];
            }
        }
    }
    
    const YKSBLEConnectionYLinkStatus lastStatus = [[self.yLinkKnownStates lastObject] intValue];
    YKSBLEConnectionYLinkStatus secondToLast = -1;
    
    if ([self.yLinkKnownStates count] > 1) {
        secondToLast = [[self.yLinkKnownStates objectAtIndex:(self.yLinkKnownStates.count - 2)] intValue];
    }
    
    if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
        && secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
        
        if (self.totalTimeInterval == 0.f) {
            self.statusLabel.text = @"... s";
        }
        else {
            self.statusLabel.text = [NSString stringWithFormat:@"%.2f s", self.totalTimeInterval];
        }
        
        self.trackIdLabel.textColor = [UIColor greenColor];
        self.roomNumberLabel.textColor = [UIColor greenColor];
        self.statusLabel.textColor = [UIColor greenColor];
        
        // Last bar is green
        [strokeColours removeLastObject];
        [strokeColours addObject:[UIColor greenColor]];

    }
    
    else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
             && secondToLast == YKSBLEConnectionYLinkDisconnected) {
        
        if (self.totalTimeInterval == 0.f) {
            self.statusLabel.text = @"... s";
        }
        else {
            self.statusLabel.text = [NSString stringWithFormat:@"%.2f s", self.totalTimeInterval];
        }
        
        self.trackIdLabel.textColor = [UIColor greenColor];
        self.roomNumberLabel.textColor = [UIColor greenColor];
        self.statusLabel.textColor = [UIColor greenColor];
        
        [strokeColours removeLastObject];
        [strokeColours addObject:[UIColor greenColor]];
    }
    else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
             && secondToLast == YKSBLEConnectionYLinkExpired) {
        self.statusLabel.text = @"expired";
        
        self.trackIdLabel.textColor = [UIColor lightGrayColor];
        self.roomNumberLabel.textColor = [UIColor lightGrayColor];
        self.statusLabel.textColor = [UIColor orangeColor];

    }
    else if (lastStatus == YKSBLEConnectionYLinkConnected
             || ( lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                 && secondToLast == YKSBLEConnectionYLinkConnected)) {
                 
                 if (self.totalTimeInterval == 0.f) {
                     self.statusLabel.text = @"... s";
                 }
                 else {
                     self.statusLabel.text = [NSString stringWithFormat:@"%.2f s", self.totalTimeInterval];
                 }
                 
                 self.trackIdLabel.textColor = [UIColor greenColor];
                 self.roomNumberLabel.textColor = [UIColor greenColor];
                 self.statusLabel.textColor = [UIColor greenColor];
                 
                 [strokeColours removeLastObject];
                 [strokeColours addObject:[UIColor greenColor]];
             }
    else if (lastStatus == YKSBLEConnectionYLinkConnected
             && [self.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkDiscoveredDoor)]
             && ! [self.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]
             ) {
        self.statusLabel.text = @"connected";
        
        self.trackIdLabel.textColor = [UIColor greenColor];
        self.roomNumberLabel.textColor = [UIColor greenColor];
        self.statusLabel.textColor = [UIColor greenColor];
        
        [strokeColours removeLastObject];
        [strokeColours addObject:[UIColor greenColor]];
    }
    else if (lastStatus == YKSBLEConnectionYLinkDisconnected
             && ! [self.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkReceivedWriteConf)]
             && ! [self.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
        
        self.statusLabel.text = @"in progress";
        self.trackIdLabel.textColor = [UIColor whiteColor];
        self.roomNumberLabel.textColor = [UIColor whiteColor];
        self.statusLabel.textColor = [UIColor whiteColor];
    }
    else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished) {
        
        const YKSBLEConnectionYLinkStatus secondToLast = [[self.yLinkKnownStates objectAtIndex:(self.yLinkKnownStates.count - 2)] intValue];
        
        if (secondToLast == YKSBLEConnectionYLinkExpired) {
            self.statusLabel.text = @"expired";
            
            self.trackIdLabel.textColor = [UIColor lightGrayColor];
            self.roomNumberLabel.textColor = [UIColor lightGrayColor];
            self.statusLabel.textColor = [UIColor orangeColor];
        }
    }
    
    else if (lastStatus == YKSBLEConnectionYLinkFailed) {
        
        self.statusLabel.text = @"failed";
        self.trackIdLabel.textColor = [UIColor yellowColor];
        self.roomNumberLabel.textColor = [UIColor yellowColor];
        self.statusLabel.textColor = [UIColor redColor];
    }
    else if (lastStatus == YKSBLEConnectionYLinkStartedScan){
        
        self.statusLabel.text = @"in progress";
        self.trackIdLabel.textColor = [UIColor whiteColor];
        self.roomNumberLabel.textColor = [UIColor whiteColor];
        self.statusLabel.textColor = [UIColor whiteColor];
    }
    
    else if (lastStatus == YKSBLEConnectionYLinkDiscoveredDoor) {
        
        self.statusLabel.text = @"discov";
        self.trackIdLabel.textColor = [UIColor whiteColor];
        self.roomNumberLabel.textColor = [UIColor whiteColor];
        self.statusLabel.textColor = [UIColor whiteColor];
    }

    
    if (shouldAddBarChart) {
        
        CGRect barChartFrame;
        DeviceVersion devVers = [SDiPhoneVersion deviceVersion];
        
        if (devVers == iPhone4 || devVers == iPhone4S) {
            
            barChartFrame = CGRectMake(self.barChartViewHolder.frame.origin.x,
                                       self.barChartViewHolder.frame.origin.y,
                                       250.0,
                                       self.barChartViewHolder.frame.size.height);
        }
        else {
            barChartFrame = self.barChartViewHolder.frame;
        }
        
        NSMutableArray *yLabelsLegends = [NSMutableArray array];
        NSMutableArray *ySetValues = [NSMutableArray array];
        
        // These value will be hidden since the text is not set inside PNBarChart.m line 127 ( coincidence! )
        [yLabelsLegends addObject:[NSNumber numberWithInt:0]];
        [yLabelsLegends addObject:[NSNumber numberWithInt:127]];
        
        for (NSNumber *number in rssiAbsoluteValuesNumbers) {
            
            int oldRSSIValue = number.intValue;
            
            if (127 != oldRSSIValue) {
                int newRSSIValue = 127 - oldRSSIValue;
                [ySetValues addObject:[NSNumber numberWithInt:newRSSIValue]];
            }
            else {
                [ySetValues addObject:[NSNumber numberWithInt:oldRSSIValue]];
            }
        }
        
        self.barChart = [[PNBarChart alloc] initWithFrame:barChartFrame];
        self.barChart.backgroundColor = [UIColor whiteColor];
        self.barChart.yChartLabelWidth = 20.0;
        self.barChart.chartMarginLeft = 30.0;
        self.barChart.chartMarginRight = 10.0;
        self.barChart.chartMarginTop = 5.0;
        self.barChart.chartMarginBottom = 10.0;
        
        
        self.barChart.labelMarginTop = 5.0;
        self.barChart.showChartBorder = YES;
        
        [self.barChart setXLabels:rssiValuesStrings];
        self.barChart.yLabels = yLabelsLegends;
        self.barChart.yValues = ySetValues;
        [self.barChart setStrokeColors:strokeColours];
        
        self.barChart.yMaxValue = maxValue - minValue + 10;
        self.barChart.yMinValue = 0;
        
        self.barChart.isGradientShow = NO;
        self.barChart.isShowNumbers = NO;
        
        [self.barChart strokeChart];
        
        [self.barChart setCenter:CGPointMake(self.barChartViewHolder.frame.size.width /2, self.barChartViewHolder.frame.size.height / 2)];
        
        [self.barChartViewHolder addSubview:self.barChart];
        
        self.rssiTextLegendLabel.hidden = NO;
    }
    else {
        UILabel *noRssiDataLabel = [[UILabel alloc] initWithFrame:self.barChartViewHolder.frame];
        
        noRssiDataLabel.text = @"No RSSI values recorded";
        noRssiDataLabel.textAlignment = NSTextAlignmentCenter;
        [noRssiDataLabel setCenter:CGPointMake(self.barChartViewHolder.frame.size.width /2, self.barChartViewHolder.frame.size.height / 2)];
        [self.barChartViewHolder addSubview:noRssiDataLabel];
        
        self.rssiTextLegendLabel.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
