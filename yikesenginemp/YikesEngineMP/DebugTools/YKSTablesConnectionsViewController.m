//
//  YKSDebugConsoleTableViewController.m
//  yikes
//
//  Created by royksopp on 2015-02-03.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSTablesConnectionsViewController.h"
#import "YKSDebugConsoleBLETriangleActiveCell.h"
#import "YKSDebugConsoleBLETriangleFinishedCell.h"
#import "BLETriangleConnection.h"
#import "YKSDebugManager.h"
#import "YKSDebugManager+BLEConnectionsSimulation.h"
#import "YBLEManager.h"
#import "WYPopoverController.h"
#import "YKSRSSIHistogramViewController.h"
#import "SDiPhoneVersion.h"
#import "Colours.h"
#import "YKSBinaryHelper.h"

@import YikesSharedModel;

const int MAX_CHARS_ROOM_NUMBER_IN_DEBUG_CONSOLE = 8;

@interface YKSTablesConnectionsViewController () <UITableViewDelegate, UITableViewDataSource, YKSDebugBLEConnectionsDataAvailableDelegate, WYPopoverControllerDelegate>

@property (strong, nonatomic) NSArray *localActiveConnections;
@property (strong, nonatomic) NSArray *localFinishedConnections;

@property (strong, nonatomic) NSArray *localTemporaryActiveConnectionsCopy;
@property (strong, nonatomic) NSArray *localTemporaryFinishedConnectionsCopy;

@property (strong, nonatomic) WYPopoverController* rssiHistogramPopoverController;
@property (nonatomic, strong) NSTimer *timer;

@property (atomic, assign) BOOL isReloadingTableViews;
@property (atomic, assign) BOOL isReloadingTableViewsScheduled;
@end

@implementation YKSTablesConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DeviceVersion deviceVersion = [SDiPhoneVersion deviceVersion];
    
    if (deviceVersion == iPhone4S) {
        self.finishedConnectionsTableHeightConstraint.constant = 54.0;
    }
    
    [self.finishedConnectionsTableView setHidden:YES];
    
    [self.finishedConnectionsTableView setDelegate:self];
    [self.finishedConnectionsTableView setDataSource:self];
    [self.activeConnectionsTableView setDelegate:self];
    [self.activeConnectionsTableView setDataSource:self];
    
    [self.finishedConnectionsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.finishedConnectionsTableView setSeparatorColor:[UIColor clearColor]];
    
    [self.activeConnectionsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.activeConnectionsTableView setSeparatorColor:[UIColor clearColor]];

    [YKSDebugManager sharedManager].availableBLEConnectionsDataDelegate = self;
    
    self.finishedConnectionsTableView.backgroundView = nil;
    self.finishedConnectionsTableView.backgroundColor = [UIColor blackColor];
    
    self.activeConnectionsTableView.backgroundView = nil;
    self.activeConnectionsTableView.backgroundColor = [UIColor blackColor];
    
    
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    [self.activeConnectionsTableView addGestureRecognizer:lpgr];
    
    
    // For debugging only, calling method declared in category
//    [[YKSDebugManager sharedManager] createFakeConnection];
//    [[YKSDebugManager sharedManager] startAddingNewRSSIValues];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.finishedConnectionsTableView reloadData];
    [self scrollActiveAndFinishedTableViewsToBottom];
    [self.finishedConnectionsTableView setHidden:NO];
    
    if (! self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimers:) userInfo:nil repeats:YES];
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.activeConnectionsTableView];
    
    NSIndexPath *indexPath = [self.activeConnectionsTableView indexPathForRowAtPoint:p];
    
    if (indexPath == nil) {
        // Long press on table view but not on a row
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSUInteger index = indexPath.row;
        
//        [[YKSDebugManager sharedManager] logMessage:[NSString stringWithFormat:@"Long press detected on row: %lu", index] withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeDevice];
        
        if (index < [self.localActiveConnections count]) {
            BLETriangleConnection* oneConnection = [self.localActiveConnections objectAtIndex:index];
            
            if (oneConnection) {
                
                const YKSBLEConnectionYLinkStatus lastConnectionStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
                
                if (lastConnectionStatus == YKSBLEConnectionYLinkConnected) {
                    [[YBLEManager sharedManager] disconnectFromyLinkWithTrackID:[oneConnection yLinkTrackID]];
                }
                else if (lastConnectionStatus == YKSBLEConnectionYLinkProcessedAndFinished) {
                    const YKSBLEConnectionYLinkStatus secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
                    
                    if (secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
                        [[YBLEManager sharedManager] disconnectFromyLinkWithTrackID:[oneConnection yLinkTrackID]];
                    }
                }
            }
        }

    } else {
        // Another state, not used
    }
}

#pragma mark -

- (void)updateTimers:(NSTimer *)timer {
    
    NSArray *visibleCellsIndexPaths = [self.activeConnectionsTableView indexPathsForVisibleRows];
    NSArray *connections = self.localActiveConnections;
    
    
    for (NSIndexPath *indexPath in visibleCellsIndexPaths) {
        if (indexPath) {
    
            YKSDebugConsoleBLETriangleActiveCell *activeConnectionCell = [self.activeConnectionsTableView cellForRowAtIndexPath:indexPath];
            
            BLETriangleConnection* oneConnection = [connections objectAtIndex:indexPath.row];
            
            const YKSBLEConnectionYLinkStatus lastStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
            
            if ((lastStatus == YKSBLEConnectionYLinkStartedScan) || (lastStatus == YKSBLEConnectionYLinkDiscoveredDoor)) {
                
                NSDate *now = [NSDate date];
                NSDate *startTime = [oneConnection yLinkStartDate];
                
                NSTimeInterval elapsedTime = [now timeIntervalSinceDate:startTime];
                elapsedTime = oneConnection.timeout - elapsedTime;
                
                UIColor *color;
                
                if (0 <= elapsedTime <= oneConnection.timeout) {
                    color = [UIColor colorWithHue:( 0.4 * (elapsedTime / oneConnection.timeout)) saturation:0.9 brightness:0.9 alpha:1.0];
                }
                else {
                    color = [UIColor redColor];
                }
                
                activeConnectionCell.elapsedTimeInfo.textColor = color;
                
                if (activeConnectionCell) {
                    activeConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.0f s", elapsedTime];
                }
                
            }
        }
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark -
- (void)setRoomNumber:(NSString*)room toLabel:(UILabel*)label {
    if (room) {
        
        NSMutableString *roomNumber = [NSMutableString stringWithString:room];
        
        if (roomNumber && roomNumber.length > MAX_CHARS_ROOM_NUMBER_IN_DEBUG_CONSOLE) {
            [roomNumber insertString:@"-\r" atIndex:MAX_CHARS_ROOM_NUMBER_IN_DEBUG_CONSOLE];
            label.numberOfLines = 2;
        }
        else {
            label.numberOfLines = 1;
        }
        
        label.text = roomNumber;
    }
    else {
        label.text = @"";
    }
}


- (void)setNumberOfRSSIReadingsFromConnection:(BLETriangleConnection *)bleTriangleConnection toLabel:(UILabel *)numberOfRSSILabel {
    
    NSUInteger numberOfRSSIReadings = [bleTriangleConnection.rssiValues count];
    numberOfRSSILabel.text = [NSString stringWithFormat:@"%lu", (unsigned long) numberOfRSSIReadings];
    
    if (bleTriangleConnection.hasBadRSSIReading) {
        numberOfRSSILabel.textColor = [UIColor dangerColor];
    }
    else if (bleTriangleConnection.hasReceivedWriteConfirmation) {
        numberOfRSSILabel.textColor = [UIColor infoBlueColor];
    }
    else if (0 == numberOfRSSIReadings) {
        numberOfRSSILabel.textColor = [UIColor whiteColor];
    }
    else {
        numberOfRSSILabel.textColor = [UIColor orangeColor];
    }

    
}


#pragma mark -
- (void)scrollActiveAndFinishedTableViewsToBottom {

    BOOL isScrollingPaused = [YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController;
    
    if (! isScrollingPaused) {
        if (self.activeConnectionsTableView.contentSize.height > self.activeConnectionsTableView.frame.size.height)
        {
            CGPoint offset = CGPointMake(0, self.activeConnectionsTableView.contentSize.height - self.activeConnectionsTableView.frame.size.height);
            [self.activeConnectionsTableView setContentOffset:offset animated:YES];
        }
        
        
        if (self.finishedConnectionsTableView.contentSize.height > self.finishedConnectionsTableView.frame.size.height)
        {
            CGPoint offset = CGPointMake(0, self.finishedConnectionsTableView.contentSize.height - self.finishedConnectionsTableView.frame.size.height);
            [self.finishedConnectionsTableView setContentOffset:offset animated:YES];
        }
    }
}

#pragma mark - YKSDebugBLEConnectionsDataAvailableDelegate

- (void)bleConnectionsDataAvailableWithActiveConnections:(NSArray *)activeConnections
                                  andFinishedConnections:(NSArray *)finishedConnections
{
    self.localTemporaryActiveConnectionsCopy = activeConnections;
    self.localTemporaryFinishedConnectionsCopy = finishedConnections;
    
    
    if (self.isReloadingTableViews) {
        
        if (self.isReloadingTableViewsScheduled) {
            //NSLog(@">>>>CONNECTIONS>> Skipping TableViews reloading");
        }
        else {
            [self performSelector:@selector(callBleConnectionsDataAvailable) withObject:nil afterDelay:0.150];
            self.isReloadingTableViewsScheduled = YES;
            
            //NSLog(@">>>>CONNECTIONS>> Scheduled TableViews reloading");
        }
    }
    else {
        
        if (self.isReloadingTableViewsScheduled) {
            [YKSTablesConnectionsViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(callBleConnectionsDataAvailable) object:nil];
            self.isReloadingTableViewsScheduled = NO;
            
            //NSLog(@">>>>CONNECTIONS>> Unscheduled TableViews reloading");
        }
        
        //NSLog(@">>>>CONNECTIONS>> Reloading TableViews");
        
        self.isReloadingTableViews = YES;
        self.localActiveConnections = [[NSArray alloc] initWithArray:self.localTemporaryActiveConnectionsCopy copyItems:YES];
        self.localFinishedConnections = [[NSArray alloc] initWithArray:self.localTemporaryFinishedConnectionsCopy copyItems:YES];
        
        [self.activeConnectionsTableView reloadData];
        [self.finishedConnectionsTableView reloadData];
        [self scrollActiveAndFinishedTableViewsToBottom];
        
        self.isReloadingTableViews = NO;
    }
}



- (void)callBleConnectionsDataAvailable {
    [self bleConnectionsDataAvailableWithActiveConnections:self.localTemporaryActiveConnectionsCopy
                                    andFinishedConnections:self.localTemporaryFinishedConnectionsCopy];
}




#pragma mark
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger index = indexPath.row;
    
    if (tableView == self.finishedConnectionsTableView) {
        // Show RSSI histogram
        if (index < [self.localFinishedConnections count]) {
            BLETriangleConnection *finishedConnection = [self.localFinishedConnections objectAtIndex:index];
            
            if (finishedConnection) {
                NSMutableArray *scanedRSSIValues = [NSMutableArray arrayWithArray:finishedConnection.rssiValues];
                
                NSString* trackId = [YKSBinaryHelper hexStringFromBinary:[finishedConnection yLinkTrackID]];
                
                NSLog(@"RSSI values for connection with trackId: %@", trackId);
                
                for (NSNumber *oneRSSIValue in scanedRSSIValues) {
                    NSLog(@"%d", oneRSSIValue.intValue);
                }
                
                if ([self.rssiHistogramPopoverController isPopoverVisible]) {
                    [self.rssiHistogramPopoverController dismissPopoverAnimated:YES];
                }
                else
                {
                    NSBundle *bundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewStoryboard" bundle:bundle];
                    
                    UIViewController *rssiHistogramViewController = [storyboard instantiateViewControllerWithIdentifier:@"RSSIHistogramViewControllerSBID"];
                    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                
                    
                    YKSRSSIHistogramViewController *rssiHistoVC = ((YKSRSSIHistogramViewController *) rssiHistogramViewController);
                    
                    [rssiHistoVC setRssiValuesArray:[NSMutableArray arrayWithArray:scanedRSSIValues]];
                    [rssiHistoVC setYManMacAddress:[finishedConnection yManMacAddress]];
                    [rssiHistoVC setTrackId:[finishedConnection yLinkTrackID]];
                    [rssiHistoVC setRoomNumber:finishedConnection.roomNumber];
                    [rssiHistoVC setYLinkStartTime:finishedConnection.yLinkStartDate];
                    [rssiHistoVC setYLinkKnownStates:[NSMutableArray arrayWithArray:finishedConnection.yLinkKnownStates]];
                    [rssiHistoVC setTotalTimeInterval:finishedConnection.yLinkTimeInterval];
                    [rssiHistoVC setRssiThresholdValue:finishedConnection.rssiThreshold];
                    
                    rssiHistogramViewController.preferredContentSize = CGSizeMake(screenWidth, 350);
                    rssiHistogramViewController.modalPresentationStyle = UIModalPresentationPopover;
                    
                    CGRect startArrow = CGRectMake(0, 0, 10, 10);
                    
                    self.rssiHistogramPopoverController = [[WYPopoverController alloc] initWithContentViewController:rssiHistogramViewController];
                    
                    self.rssiHistogramPopoverController.theme = [WYPopoverTheme themeForIOS7];
                    [self.rssiHistogramPopoverController beginThemeUpdates];
                    self.rssiHistogramPopoverController.theme.borderWidth = 6;
                    self.rssiHistogramPopoverController.theme.fillTopColor = [UIColor blackColor];
                    [self.rssiHistogramPopoverController endThemeUpdates];
                    
                    self.rssiHistogramPopoverController.delegate = self;
                    [self.rssiHistogramPopoverController presentPopoverFromRect:startArrow inView:self.view permittedArrowDirections:WYPopoverArrowDirectionNone animated:YES];
                }
                
            }
        }
        
    }
    else if (tableView == self.activeConnectionsTableView){

        // Show RSSI histogram
        if (index < [self.localActiveConnections count]) {
            BLETriangleConnection *activeConnection = [self.localActiveConnections objectAtIndex:index];
            
            if (activeConnection) {
                NSMutableArray *scanedRSSIValues = [NSMutableArray arrayWithArray:activeConnection.rssiValues];
                
                NSString* trackId = [YKSBinaryHelper hexStringFromBinary:[activeConnection yLinkTrackID]];
                
                NSLog(@"RSSI values for connection with trackId: %@", trackId);
                
                for (NSNumber *oneRSSIValue in scanedRSSIValues) {
                    NSLog(@"%d", oneRSSIValue.intValue);
                }
                
                if ([self.rssiHistogramPopoverController isPopoverVisible]) {
                    [self.rssiHistogramPopoverController dismissPopoverAnimated:YES];
                }
                else
                {
                    NSBundle *bundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewStoryboard" bundle:bundle];
                    
                    UIViewController *rssiHistogramViewController = [storyboard instantiateViewControllerWithIdentifier:@"RSSIHistogramViewControllerSBID"];
                    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                    
                    
                    YKSRSSIHistogramViewController *rssiHistoVC = ((YKSRSSIHistogramViewController *) rssiHistogramViewController);
                    
                    [rssiHistoVC setRssiValuesArray:[NSMutableArray arrayWithArray:scanedRSSIValues]];
                    [rssiHistoVC setYManMacAddress:[activeConnection yManMacAddress]];
                    [rssiHistoVC setTrackId:[activeConnection yLinkTrackID]];
                    [rssiHistoVC setRoomNumber:activeConnection.roomNumber];
                    [rssiHistoVC setYLinkStartTime:activeConnection.yLinkStartDate];
                    [rssiHistoVC setYLinkKnownStates:[NSMutableArray arrayWithArray:activeConnection.yLinkKnownStates]];
                    [rssiHistoVC setTotalTimeInterval:activeConnection.yLinkTimeInterval];
                    [rssiHistoVC setRssiThresholdValue:activeConnection.rssiThreshold];
                    
                    rssiHistogramViewController.preferredContentSize = CGSizeMake(screenWidth, 350);
                    rssiHistogramViewController.modalPresentationStyle = UIModalPresentationPopover;
                    
                    CGRect startArrow = CGRectMake(0, 0, 10, 10);
                    
                    self.rssiHistogramPopoverController = [[WYPopoverController alloc] initWithContentViewController:rssiHistogramViewController];
                    
                    self.rssiHistogramPopoverController.theme = [WYPopoverTheme themeForIOS7];
                    [self.rssiHistogramPopoverController beginThemeUpdates];
                    self.rssiHistogramPopoverController.theme.borderWidth = 6;
                    self.rssiHistogramPopoverController.theme.fillTopColor = [UIColor blackColor];
                    [self.rssiHistogramPopoverController endThemeUpdates];
                    
                    self.rssiHistogramPopoverController.delegate = self;
                    [self.rssiHistogramPopoverController presentPopoverFromRect:startArrow inView:self.view permittedArrowDirections:WYPopoverArrowDirectionNone animated:YES];
                }
            }
        }
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.finishedConnectionsTableView) {
        return 18;
    }
    else if (tableView == self.activeConnectionsTableView){
        return 18;
    }
    
    return 0;
}


#pragma mark
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (tableView == self.finishedConnectionsTableView) {
        return 1;
    }
    else if (tableView == self.activeConnectionsTableView){
        return 1;
    }
    
    return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.finishedConnectionsTableView) {
        
        if (! self.localFinishedConnections) {
            return 0;
        }
        
        return [self.localFinishedConnections count];
    }
    else if (tableView == self.activeConnectionsTableView) {
        if (! self.localActiveConnections) {
            return 0;
        }
        
        return [self.localActiveConnections count];
    }
    
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //TODO: improve performance, keep cases that are valid for each table view (finished and active)
    
    YKSDebugConsoleBLETriangleActiveCell *activeConnectionCell;
    YKSDebugConsoleBLETriangleFinishedCell *finishedConnectionCell;
    
    if (tableView == self.finishedConnectionsTableView) {

        NSArray *connections = self.localFinishedConnections;
        
        finishedConnectionCell = [tableView dequeueReusableCellWithIdentifier:@"bleTriangleCellFinished" forIndexPath:indexPath];
        BLETriangleConnection* oneConnection = [connections objectAtIndex:indexPath.row];
        
        NSString* yManMacAddresHex = [YKSBinaryHelper hexStringFromBinary:[oneConnection yManMacAddress]];
        yManMacAddresHex = [yManMacAddresHex substringFromIndex:MAX([yManMacAddresHex length] - 4, 0)];
        NSString* yLinkTrackIDHex = [YKSBinaryHelper hexStringFromBinary:[oneConnection yLinkTrackID]];
        
        finishedConnectionCell.yManInfo.text = yManMacAddresHex;
        finishedConnectionCell.yLinkInfo.text = yLinkTrackIDHex;
        
        [self setNumberOfRSSIReadingsFromConnection:oneConnection toLabel:finishedConnectionCell.numberOfRSSIReadings];
        
        const YKSBLEConnectionYLinkStatus lastStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
        YKSBLEConnectionYLinkStatus secondToLast = -1;
        
        if ([oneConnection.yLinkKnownStates count] > 1) {
            secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
        }
        
        if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
            && secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
            
            if ([oneConnection yLinkTimeInterval] == 0.f) {
                finishedConnectionCell.elapsedTimeInfo.text = @"... s";
            }
            else {
                finishedConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.2f s", [oneConnection yLinkTimeInterval]];
            }
            
            
            finishedConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor greenColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
            
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        
        else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                 && secondToLast == YKSBLEConnectionYLinkDisconnected) {
            
            if ([oneConnection yLinkTimeInterval] == 0.f) {
                finishedConnectionCell.elapsedTimeInfo.text = @"... s";
            }
            else {
                finishedConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.2f s", [oneConnection yLinkTimeInterval]];
            }
            
            finishedConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor greenColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
            
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                 && secondToLast == YKSBLEConnectionYLinkExpired) {
            finishedConnectionCell.elapsedTimeInfo.text = @"expired";
            
            finishedConnectionCell.yLinkInfo.textColor = [UIColor lightGrayColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor lightGrayColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor orangeColor];
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        else if (lastStatus == YKSBLEConnectionYLinkConnected
                 || ( lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                     && secondToLast == YKSBLEConnectionYLinkConnected)) {
                     
                     NSDate *now = [NSDate date];
                     NSDate *startTime = [oneConnection yLinkStartDate];
                     
                     NSTimeInterval elapsedTime = [now timeIntervalSinceDate:startTime];
                     
                     if (activeConnectionCell) {
                         activeConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.0f s", elapsedTime];
                     }
                     
                     finishedConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
                     finishedConnectionCell.roomNumber.textColor = [UIColor greenColor];
                     finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
                     [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
                 }
        else if (lastStatus == YKSBLEConnectionYLinkConnected
                 && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkDiscoveredDoor)]
                 && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                 ) {
            finishedConnectionCell.elapsedTimeInfo.text = @"connected";
            finishedConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor greenColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
            
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        
        else if (lastStatus == YKSBLEConnectionYLinkDisconnected
                 && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkReceivedWriteConf)]
                 && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
            
            finishedConnectionCell.elapsedTimeInfo.text = @"in progress";
            finishedConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor whiteColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
            
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        
        else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished) {
            
            const YKSBLEConnectionYLinkStatus secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
            
            if (secondToLast == YKSBLEConnectionYLinkExpired) {
                finishedConnectionCell.elapsedTimeInfo.text = @"expired";
                
                finishedConnectionCell.yLinkInfo.textColor = [UIColor lightGrayColor];
                finishedConnectionCell.roomNumber.textColor = [UIColor lightGrayColor];
                finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor orangeColor];
                
                [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
            }
        }
        
        else if (lastStatus == YKSBLEConnectionYLinkFailed) {
            
            finishedConnectionCell.elapsedTimeInfo.text = @"failed";
            finishedConnectionCell.yLinkInfo.textColor = [UIColor yellowColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor yellowColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor redColor];
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
            
        }
        else if (lastStatus == YKSBLEConnectionYLinkStartedScan){
            
            finishedConnectionCell.elapsedTimeInfo.text = @"in progress";
            
            finishedConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor whiteColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        
        else if (lastStatus == YKSBLEConnectionYLinkDiscoveredDoor) {
            
            finishedConnectionCell.elapsedTimeInfo.text = @"discov";
            finishedConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
            finishedConnectionCell.roomNumber.textColor = [UIColor whiteColor];
            finishedConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
            [self setRoomNumber:oneConnection.roomNumber toLabel:finishedConnectionCell.roomNumber];
        }
        
        finishedConnectionCell.yManInfo.textColor = [UIColor greenColor];
        
        NSDateFormatter *formatter = [[YKSDateHelper sharedInstance] timeOnlyHHmmssDateFormatter];
        
        NSDate *yLinkStartDate = oneConnection.yLinkStartDate;
        finishedConnectionCell.startTimeLabel.text = [formatter stringFromDate:yLinkStartDate];
        
        return finishedConnectionCell;
        
    }
    else if (tableView == self.activeConnectionsTableView) {
        
        activeConnectionCell = [tableView dequeueReusableCellWithIdentifier:@"bleTriangleCell" forIndexPath:indexPath];

        BOOL foundActiveConnection = NO;
        
        NSUInteger index = indexPath.row;
        
        if (index < [self.localActiveConnections count]) {

            BLETriangleConnection* oneConnection = [self.localActiveConnections objectAtIndex:indexPath.row];
            
            if (oneConnection) {
                
                foundActiveConnection = YES;
                
                NSString* yManMacAddresHex = [YKSBinaryHelper hexStringFromBinary:[oneConnection yManMacAddress]];
                yManMacAddresHex = [yManMacAddresHex substringFromIndex:MAX([yManMacAddresHex length] - 4, 0)];
                NSString* yLinkTrackIDHex = [YKSBinaryHelper hexStringFromBinary:[oneConnection yLinkTrackID]];
                
                [self setNumberOfRSSIReadingsFromConnection:oneConnection toLabel:activeConnectionCell.numberOfRSSIReadings];
                
                activeConnectionCell.yManInfo.text = yManMacAddresHex;
                activeConnectionCell.yLinkInfo.text = yLinkTrackIDHex;
                
                UIActivityIndicatorView *spinner;
                
                const YKSBLEConnectionYLinkStatus lastStatus = [[oneConnection.yLinkKnownStates lastObject] intValue];
                YKSBLEConnectionYLinkStatus secondToLast = -1;
                
                if ([oneConnection.yLinkKnownStates count] > 1) {
                    secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
                }
                
                
                if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                    && secondToLast == YKSBLEConnectionYLinkReceivedWriteConf) {
                    
                    if (activeConnectionCell) {
                        
                        if (isnan(oneConnection.yLinkTimeInterval)) {
                            activeConnectionCell.elapsedTimeInfo.text = @"... s";
                        }
                        else {
                            activeConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.0f s", oneConnection.yLinkTimeInterval];
                        }
                    }
                    
                    activeConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor greenColor];
                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
                    
                    [activeConnectionCell.RSSILabel setHidden:YES];
                    activeConnectionCell.RSSILabel.text = @"";
                    
                    [activeConnectionCell.connectedDot setHidden:NO];
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    [activeConnectionCell.progressView setHidden:YES];
                }
                
                else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                         && secondToLast == YKSBLEConnectionYLinkDisconnected) {
                    
                    if ([oneConnection yLinkTimeInterval] == 0.f) {
//                        activeConnectionCell.elapsedTimeInfo.text = @"... s";
                    }
                    else {
//                        activeConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.2f s", [oneConnection totalTimeInterval]];
                    }
                    
                    activeConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor greenColor];
//                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
                    
                    [activeConnectionCell.RSSILabel setHidden:YES];
                    activeConnectionCell.RSSILabel.text = @"";
                    
                    [activeConnectionCell.connectedDot setHidden:YES];
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    [activeConnectionCell.progressView setHidden:YES];
                }
                else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                         && secondToLast == YKSBLEConnectionYLinkExpired) {
                    activeConnectionCell.elapsedTimeInfo.text = @"expired";
                    
                    activeConnectionCell.yLinkInfo.textColor = [UIColor lightGrayColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor lightGrayColor];
                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor orangeColor];
                    [activeConnectionCell.connectedDot setHidden:YES];
                    [activeConnectionCell.RSSILabel setHidden:YES];
                    activeConnectionCell.RSSILabel.text = @"";
                    [activeConnectionCell.progressView setHidden:YES];
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                }
                else if (lastStatus == YKSBLEConnectionYLinkConnected
                         || ( lastStatus == YKSBLEConnectionYLinkProcessedAndFinished
                             && secondToLast == YKSBLEConnectionYLinkConnected)) {
                             
                             if ([oneConnection yLinkTimeInterval] == 0.f) {
//                                 activeConnectionCell.elapsedTimeInfo.text = @"... s";
                             }
                             else {
//                                 activeConnectionCell.elapsedTimeInfo.text = [NSString stringWithFormat:@"%.2f s", [oneConnection totalTimeInterval]];
                             }
                             
                             
                             activeConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
                             activeConnectionCell.roomNumber.textColor = [UIColor greenColor];
//                             activeConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
                             
                             [activeConnectionCell.RSSILabel setHidden:YES];
                             activeConnectionCell.RSSILabel.text = @"";
                             
                             [activeConnectionCell.connectedDot setHidden:YES];
                             
                             [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                             
                             if ([oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkConnected)]) {
                                 activeConnectionCell.connectedDot.hidden = NO;
                                 [activeConnectionCell.progressView setHidden:YES];
                             }
                             else {
                                 activeConnectionCell.connectedDot.hidden = YES;
                             }
                         }
                else if (lastStatus == YKSBLEConnectionYLinkConnected
                         && [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkDiscoveredDoor)]
                         && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]
                         ) {
//                    activeConnectionCell.elapsedTimeInfo.text = @"connected";
                    activeConnectionCell.yLinkInfo.textColor = [UIColor greenColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor greenColor];
//                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor greenColor];
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    [activeConnectionCell.connectedDot setHidden:NO];
                    [activeConnectionCell.progressView setHidden:YES];
                    [activeConnectionCell.RSSILabel setHidden:YES];
                    activeConnectionCell.RSSILabel.text = @"";
                    
                }
                
                else if (lastStatus == YKSBLEConnectionYLinkDisconnected
                         && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkReceivedWriteConf)]
                         && ! [oneConnection.yLinkKnownStates containsObject:@(YKSBLEConnectionYLinkProcessedAndFinished)]) {
                    
//                    activeConnectionCell.elapsedTimeInfo.text = @"in progress";
                    activeConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor whiteColor];
//                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
                    [activeConnectionCell.connectedDot setHidden:YES];
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    spinner = [[UIActivityIndicatorView alloc]
                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                    spinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    spinner.hidesWhenStopped = YES;
                    [activeConnectionCell.progressView setHidden:NO];
                    [activeConnectionCell.progressView addSubview:spinner];
                    
                    if (oneConnection.lastScannedRSSIValue) {
                        [activeConnectionCell.RSSILabel setHidden:NO];
                        activeConnectionCell.RSSILabel.text = [NSString stringWithFormat:@"%@", oneConnection.lastScannedRSSIValue];
                        [activeConnectionCell.progressView setHidden:YES];
                    }
                    else {
                        [activeConnectionCell.RSSILabel setHidden:YES];
                        activeConnectionCell.RSSILabel.text = @"";
                        [activeConnectionCell.progressView setHidden:NO];
                    }
                    
                    [spinner startAnimating];
                    
                }
                
                else if (lastStatus == YKSBLEConnectionYLinkProcessedAndFinished) {
                    
                    const YKSBLEConnectionYLinkStatus secondToLast = [[oneConnection.yLinkKnownStates objectAtIndex:(oneConnection.yLinkKnownStates.count - 2)] intValue];
                    
                    if (secondToLast == YKSBLEConnectionYLinkExpired) {
                        activeConnectionCell.elapsedTimeInfo.text = @"expired";
                        
                        activeConnectionCell.yLinkInfo.textColor = [UIColor lightGrayColor];
                        activeConnectionCell.roomNumber.textColor = [UIColor lightGrayColor];
                        activeConnectionCell.elapsedTimeInfo.textColor = [UIColor orangeColor];
                        [activeConnectionCell.connectedDot setHidden:YES];
                        [activeConnectionCell.RSSILabel setHidden:YES];
                        activeConnectionCell.RSSILabel.text = @"";
                        
                        [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    }
                }
                
                else if (lastStatus == YKSBLEConnectionYLinkFailed) {
                    
                    activeConnectionCell.elapsedTimeInfo.text = @"failed";
                    activeConnectionCell.yLinkInfo.textColor = [UIColor yellowColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor yellowColor];
                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor redColor];
                    [activeConnectionCell.connectedDot setHidden:YES];
                    [activeConnectionCell.RSSILabel setHidden:YES];
                    activeConnectionCell.RSSILabel.text = @"";
                    
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                }
                else if (lastStatus == YKSBLEConnectionYLinkStartedScan){
                    
//                    activeConnectionCell.elapsedTimeInfo.text = @"in progress";
                    
                    activeConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor whiteColor];
//                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
                    [activeConnectionCell.connectedDot setHidden:YES];
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    spinner = [[UIActivityIndicatorView alloc]
                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                    spinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    spinner.hidesWhenStopped = YES;
                    
                    if (oneConnection.lastScannedRSSIValue) {
                        [activeConnectionCell.RSSILabel setHidden:NO];
                        activeConnectionCell.RSSILabel.text = [NSString stringWithFormat:@"%@", oneConnection.lastScannedRSSIValue];
                        [activeConnectionCell.progressView setHidden:YES];
                    }
                    else {
                        [activeConnectionCell.RSSILabel setHidden:YES];
                        activeConnectionCell.RSSILabel.text = @"";
                        [activeConnectionCell.progressView setHidden:NO];
                    }
                    
                    
                    [activeConnectionCell.progressView addSubview:spinner];
                    [spinner startAnimating];
                    
                }
                
                else if (lastStatus == YKSBLEConnectionYLinkDiscoveredDoor) {
                    
//                    activeConnectionCell.elapsedTimeInfo.text = @"discov";
                    activeConnectionCell.yLinkInfo.textColor = [UIColor whiteColor];
                    activeConnectionCell.roomNumber.textColor = [UIColor whiteColor];
//                    activeConnectionCell.elapsedTimeInfo.textColor = [UIColor whiteColor];
                    [activeConnectionCell.connectedDot setHidden:YES];
                    [self setRoomNumber:oneConnection.roomNumber toLabel:activeConnectionCell.roomNumber];
                    
                    [activeConnectionCell.progressView setHidden:YES];
                    
                    if (oneConnection.lastScannedRSSIValue) {
                        [activeConnectionCell.RSSILabel setHidden:NO];
                        activeConnectionCell.RSSILabel.text = [NSString stringWithFormat:@"%@", oneConnection.lastScannedRSSIValue];
                        [activeConnectionCell.progressView setHidden:YES];
                    }
                    else {
                        [activeConnectionCell.RSSILabel setHidden:YES];
                        activeConnectionCell.RSSILabel.text = @"";
                        [activeConnectionCell.progressView setHidden:NO];
                    }
                    
                    [activeConnectionCell.progressView addSubview:spinner];
                }
                
                activeConnectionCell.yManInfo.textColor = [UIColor greenColor];
                
                return activeConnectionCell;
                
            }
        }

        if (! foundActiveConnection) {
            activeConnectionCell.yManInfo.hidden = YES;
            activeConnectionCell.yLinkInfo.hidden = YES;
            activeConnectionCell.roomNumber.hidden = YES;
            activeConnectionCell.connectedDot.hidden = YES;
            activeConnectionCell.elapsedTimeInfo.hidden = YES;
            activeConnectionCell.progressView.hidden = YES;
            activeConnectionCell.RSSILabel.hidden = YES;
            activeConnectionCell.numberOfRSSIReadings.hidden = YES;
            
            return activeConnectionCell;
        }
        
    }

    return activeConnectionCell;
}

#pragma mark - WYPopoverControllerDelegate
- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller
{
    if (controller == self.rssiHistogramPopoverController) {
        self.rssiHistogramPopoverController.delegate = nil;
        self.rssiHistogramPopoverController = nil;
    }
    
}


#pragma mark -


- (void)bleConnectionsWithYMen:(NSMutableArray *)yMen andYLinks:(NSMutableArray *)yLinks {
}

@end
