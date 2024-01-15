//
//  YKSDebugViewController.m
//  yikes sample
//
//  Created by royksopp on 2015-04-14.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSDebugConsoleViewController.h"
#import "YKSDebugManager.h"
#import "SSZipArchive.h"
#import "YKSFileLogger.h"
#import "YKSTablesConnectionsViewController.h"
#import "YikesBLEConstants.h"
#import "YKSRequiredHardwareNotificationCenter.h"
#import "JSBadgeView.h"
#import "YKSLogger.h"
#import "YKSFileLogger.h"
#import "Colours.h"
#import "YKSLevelLogger.h"
#import "YKSHTTPClient.h"
#import "YikesEngineMP.h"
#import "WYPopoverController.h"
#import "YKSDeviceHelper.h"
#import "YMotionManager.h"
#import "YKSLocationManager.h"

@import YikesSharedModel;

#define FONT_SIZE_IN_CONSOLE 10
#define MULTI_YMAN_GAUTH_LOGS_FILE @"BLETriangleStats.csv"

#define kTransformCoefBell 0.8
#define kTransformCoefBadge 0.7

#import <ReplayKit/ReplayKit.h>

@interface YKSDebugConsoleViewController () <YBLEManagerDebugDelegate,
YKSBLEStationaryAndMotionDelegate,
UITableViewDataSource,
UITableViewDelegate,
//YKSBLEProximityStateDelegate,
YKSBLEStationaryAndMotionDelegate,
YKSDebugConsoleNewLogsAvailableDelegate,
UIPopoverPresentationControllerDelegate,
YKSRequiredHardwareNotificatioCenterDelegate,
UIActionSheetDelegate,
WYPopoverControllerDelegate,
UIDocumentInteractionControllerDelegate,
WYPopoverControllerDelegate,
RPPreviewViewControllerDelegate>

@property (strong, nonatomic) WYPopoverController* requiredHardwarePopoverController;
@property (strong, nonatomic) WYPopoverController* yManListPopoverController;

@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (strong, nonatomic) UIColor* yLinkStatusDefaultTextColor;

@property (nonatomic, strong) UIColor *activeColor;

@property (weak, nonatomic) IBOutlet UITableView *BLELogTableView;

@property (nonatomic, strong) NSMutableArray *logMsgArray;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (atomic, assign, getter=isOutsideIBeaconRegion) BOOL outsideIBeaconRegion;
@property (atomic, assign, getter=isDeviceStationary) BOOL deviceStationary;

@property (nonatomic, strong) NSFileHandle *logsCSVFileHandler;
@property (nonatomic, strong) YKSTablesConnectionsViewController *bleTriangleTVC;

@property (nonatomic,strong) UIDocumentInteractionController *docController;
@property (nonatomic, strong) NSURL *fullSessionLogsZipFileURL;

@property (weak, nonatomic) IBOutlet UIButton *startRecordingButton;


@property (strong) UITapGestureRecognizer * elevatorTapRecognizer;

// Info area


@property (weak, nonatomic) IBOutlet UILabel *gaVersionBuild;
@property (weak, nonatomic) IBOutlet UILabel *bleKitVersion;
@property (weak, nonatomic) IBOutlet UILabel *iOSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *guestEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *apiEnvironmentLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameworkVersion;
@property (weak, nonatomic) IBOutlet UIButton *engineSwitchButton;


// Hardware status

// yMan area
@property (weak, nonatomic) IBOutlet UILabel *yManCounterLabel;
@property (weak, nonatomic) IBOutlet UIView *yManScanGestureRecognizerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *yManScanProgressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *yManStaticLabel;


// Elevator yLink area
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *elevatorScanProgressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *elevatorLabel;
@property (weak, nonatomic) IBOutlet UIImageView *elevatorYLinkConnectDot;
@property (weak, nonatomic) IBOutlet UILabel *elevatorYLinkStatusLabel;

// iBeacon Motion message
@property (weak, nonatomic) IBOutlet UILabel *stationaryOutsideStatusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *notifCenterBellImageView;
@property (strong, nonatomic) UIPopoverPresentationController *yManPopoverPresentationController;
@property (strong, nonatomic) UIAlertController *switchEngineAlertController;

@property (strong, nonatomic) NSArray *localLogMessagesArrayCopy;
@property (strong, nonatomic) NSArray *localTemporaryLogMessagesArrayCopy;

@property (atomic, assign) BOOL isReloadingLogsTableView;
@property (atomic, assign) BOOL isReloadingLogsTableViewsScheduled;



@property (atomic, assign) int lastUpdateIndex;

typedef NS_ENUM(NSUInteger, AS_Enums) {
    kShareASTag,
    kSettingsASTag,
    kShareBLETriangleASTag,
    kShareFullSessionLogsFileASTag,
    kASTagPLRoomAuthModes
};

typedef NS_ENUM(NSUInteger, AV_Enums) {
    kYMANAVTag,
    kElevatorAVTag,
    kRestartSessionAVTag,
    PLRoomAuth_ModeTag
};


@end

static NSString * const PAUSE_AUTO_SCROLL = @"Pause auto scroll";
static NSString * const RESUME_AUTO_SCROLL = @"Resume auto scroll";


static NSDateFormatter* timeStampDateFormatter;


@implementation YKSDebugConsoleViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lastUpdateIndex = 0;
    
    [self.BLELogTableView setDataSource:self];
    [self.BLELogTableView setDelegate:self];
    
    [self.BLELogTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.BLELogTableView setSeparatorColor:[UIColor clearColor]];

    [YKSDebugManager sharedManager].availableLogsDataDelegate = self;
    
    self.BLELogTableView.backgroundView = nil;
    self.BLELogTableView.backgroundColor = [UIColor blackColor];

    [self prepareControls];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   
    [YKSRequiredHardwareNotificationCenter sharedCenter].requiredHardwareDelegate = self;
    
    self.yLinkStatusDefaultTextColor = self.elevatorYLinkStatusLabel.textColor;
    
    [[MultiYManGAuthDispatcher sharedInstance] setBleStationaryAndMotionDelegate:self];
    [[YKSRequiredHardwareNotificationCenter sharedCenter] readRequiredHardwareState];
    
    [YBLEManager sharedManager].debugDelegate = self;
    
    if ([YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController) {
        [self.pauseButton setTitle:RESUME_AUTO_SCROLL forState:UIControlStateNormal];
        [self.pauseButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    else {
        
        [self.pauseButton setTitle:PAUSE_AUTO_SCROLL forState:UIControlStateNormal];
        [self.pauseButton setTitleColor:self.activeColor forState:UIControlStateNormal];
    }
    
    
    // Hide yMan and Elevator yLink if device is stationary and/or outside yikes region
    BOOL isCurrentlyStationary = [[YMotionManager sharedManager] isStationary];
    BOOL isCurrentlyOutsideYikesRegion = ! [[YKSLocationManager sharedManager] isInsideYikesRegion];
    
    [self setDeviceStationary:isCurrentlyStationary];
    [self setOutsideIBeaconRegion: isCurrentlyOutsideYikesRegion];
    
    [self showStationaryOutsideMessage];
    
    if (isCurrentlyOutsideYikesRegion || isCurrentlyStationary) {
        [self hideYManRelatedItems];
        [self hideElevatorRelatedItems];
    }
    
    
    if ([RPScreenRecorder sharedRecorder].isRecording) {
        [self.startRecordingButton setTitle:@"STOP" forState:UIControlStateNormal];
    }
    else {
        [self.startRecordingButton setTitle:@"RECORD" forState:UIControlStateNormal];
    }
    

    
    
    // Displaying iOS version
    self.iOSVersionLabel.text = [NSString stringWithFormat:@"iOS %@\n", [YKSDeviceHelper osVersion]];
    self.gaVersionBuild.text = [NSString stringWithFormat:@"GA %@", [YKSDeviceHelper fullGuestAppVersion]];
    
    // Displaying API env
    NSString *apiEnvString = [YKSLevelLogger apiEnvToString:
                              [[YKSHTTPClient sharedClient] currentApiEnv]];
    self.apiEnvironmentLabel.text = apiEnvString;
    
    
    // Displaying guest email
    self.guestEmailLabel.text = [[[YikesEngineMP sharedEngine] userInfo] email];
    
    // Displaying engine version
    self.frameworkVersion.text = [NSString stringWithFormat:@"Engine v%@", [YKSDeviceHelper engineVersion]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[YKSRequiredHardwareNotificationCenter sharedCenter] readRequiredHardwareState];
    
    [[YKSDebugManager sharedManager] callConnectionsAndLogsDelegates];
}


- (void) prepareControls {
    
    if(NSClassFromString(@"RPScreenRecorder")) {
        DLog(@"ReplayKit is available!");
    }
    else {
        self.startRecordingButton.hidden = YES;
    }
    
    // Add BLE Logging View
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"HH:mm:ss"];
    self.logMsgArray = [[NSMutableArray alloc] initWithCapacity:2];
    [self.logMsgArray addObject:@"Starting BLE Logs...\n"];
    
    [self.BLELogTableView setDataSource:self];
    [self.BLELogTableView setDelegate:self];
    
    [self.BLELogTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.BLELogTableView setSeparatorColor:[UIColor clearColor]];

    
    self.stationaryOutsideStatusLabel.hidden = YES;
    self.outsideIBeaconRegion = NO;
    self.deviceStationary = NO;
    
    self.elevatorYLinkStatusLabel.text = @"";

    self.gaVersionBuild.text = [NSString stringWithFormat:@"GA %@", [YKSDeviceHelper fullGuestAppVersion]];
    self.bleKitVersion.text = [NSString stringWithFormat:@"BLE v%@", [[YBLEManager sharedManager] bleEngineVersion]];

    
    self.engineSwitchButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.engineSwitchButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.engineSwitchButton setTitle: @"MP active\nTap for more" forState: UIControlStateNormal];
    
    
    self.activeColor = [self.pauseButton titleColorForState:UIControlStateNormal];
    
    self.yManCounterLabel.text = @"0";

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnYManGestureRecognizerView)];
    self.yManScanGestureRecognizerView.userInteractionEnabled = YES;
    [self.yManScanGestureRecognizerView addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *tapOnRequiredHardware = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnRequiredHardwareView)];

    
    NSBundle *bundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
    
    UIImage *bell = [UIImage imageNamed:@"bell"];
    
    [self.notifCenterBellImageView setImage:bell];
    
    self.notifCenterBellImageView.userInteractionEnabled = YES;
    [self.notifCenterBellImageView addGestureRecognizer:tapOnRequiredHardware];
    
    self.notifCenterBellImageView.transform = CGAffineTransformMakeScale(kTransformCoefBell, kTransformCoefBell);

    [self.BLELogTableView reloadData];
    [self scrollBLELogTableViewToBottom];
}


#pragma mark - YKSRequiredHardwareNotificationCenter

- (void)requiredHardwareUpdate:(NSUInteger)number {
    
    if (number > 0) {
        
        BOOL existBadge = NO;
        
        for (UIView *aView in [self.notifCenterBellImageView subviews]) {
            if ([aView isKindOfClass:[JSBadgeView class]]) {

                JSBadgeView *badgeView  = (JSBadgeView *)aView;
                [badgeView setBadgeText:[NSString stringWithFormat:@"%ld", (unsigned long)number]];
                badgeView.transform = CGAffineTransformMakeScale(kTransformCoefBadge, kTransformCoefBadge);
                
                existBadge = YES;
            }
        }
        
        if (! existBadge) {
            JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.notifCenterBellImageView alignment:JSBadgeViewAlignmentTopRight];
            [badgeView setBadgeText:[NSString stringWithFormat:@"%ld", (unsigned long)number]];
            badgeView.transform = CGAffineTransformMakeScale(kTransformCoefBadge, kTransformCoefBadge);
        }
        
    }
    else {
        
        for (UIView *aView in [self.notifCenterBellImageView subviews]) {
            if ([aView isKindOfClass:[JSBadgeView class]]) {
                [aView removeFromSuperview];
            }
        }
    }
}


#pragma mark

- (void)hideYManRelatedItems {
    
    self.yManCounterLabel.hidden = YES;
    self.yManScanGestureRecognizerView.hidden = YES;
    self.yManScanProgressIndicator.hidden = YES;
    self.yManStaticLabel.hidden = YES;
}


- (void)hideElevatorRelatedItems {
    self.elevatorScanProgressIndicator.hidden = YES;
    [self.elevatorScanProgressIndicator stopAnimating];
    self.elevatorLabel.hidden = YES;
    self.elevatorYLinkConnectDot.hidden = YES;
    self.elevatorYLinkStatusLabel.hidden = YES;
}


#pragma mark - YKSBLEStationaryAndMotionDelegate

- (void)consoleDeviceBecameStationary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setDeviceStationary:YES];
        [self showStationaryOutsideMessage];
        [self hideElevatorRelatedItems];
        [self hideYManRelatedItems];
    });
}


- (void)consoleDeviceBecameToMove {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setDeviceStationary:NO];
        [self showStationaryOutsideMessage];
    });
}


- (void)consoleDeviceExitedIBeaconRegion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setOutsideIBeaconRegion:YES];
        [self showStationaryOutsideMessage];
        [self hideElevatorRelatedItems];
        [self hideYManRelatedItems];
    });
}


- (void)consoleDeviceEnteredIBeaconRegion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setOutsideIBeaconRegion:NO];
        [self showStationaryOutsideMessage];
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.localLogMessagesArrayCopy count];
}


// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BLECell" forIndexPath:indexPath];
    
    cell.userInteractionEnabled = YES;
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    NSUInteger index = indexPath.row;
    
    BOOL foundLogMessage = NO;
    
    if (index < [self.localLogMessagesArrayCopy count]) {
        
        NSDictionary *encapsulatedMessage = [self.localLogMessagesArrayCopy objectAtIndex:indexPath.row];
        
        if (encapsulatedMessage) {
            
            foundLogMessage = YES;
    
            NSString* logMessage = encapsulatedMessage[@"logMessage"];
            
            YKSErrorLevel errorLevel = (YKSErrorLevel) ((NSNumber *) encapsulatedMessage[@"YKSErrorLevel"]).intValue;
            
            YKSLogMessageType logMessageType = (YKSLogMessageType) ((NSNumber *) encapsulatedMessage[@"YKSLogMessageType"]).intValue;
            
            cell.textLabel.text = logMessage;
            cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE_IN_CONSOLE];
            
            switch (errorLevel) {
                case YKSErrorLevelCriticalError:
                    cell.textLabel.textColor = [UIColor redColor];
                    break;
                    
                case YKSErrorLevelError:
                    cell.textLabel.textColor = [UIColor orangeColor];
                    break;
                    
                case YKSErrorLevelWarning:
                    cell.textLabel.textColor = [UIColor yellowColor];
                    break;
                    
                case YKSErrorLevelInfo:
                    cell.textLabel.textColor = [UIColor skyBlueColor];
                    break;
                    
                case YKSErrorLevelDebug:
                    cell.textLabel.textColor = [UIColor whiteColor];
                    break;
                    
                default:
                    
                    break;
            }
            
            switch (logMessageType) {
                case YKSLogMessageTypeBLE:
                    cell.backgroundColor = [UIColor blackColor];
                    break;
                    
                case YKSLogMessageTypeAPI:
                    cell.backgroundColor = [UIColor oliveColor];
                    break;
                    
                case YKSLogMessageTypeService:
                    cell.backgroundColor = [UIColor grapeColor];
                    break;
                    
                case YKSLogMessageTypeDevice:
                    cell.backgroundColor = [UIColor eggplantColor];
                    break;
                    
                default:
                    
                    break;
            }
            
            
            if (!([logMessage rangeOfString:@"DISCOVERED ELEVATOR #0"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor greenColor];
            }
            
            if (!([logMessage rangeOfString:@"CONNECTED TO ELEVATOR #0"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor greenColor];
                self.elevatorYLinkStatusLabel.text = @"Conn Elev #0";
                self.elevatorYLinkStatusLabel.textColor = [UIColor greenColor];
            }
            
            if (!([logMessage rangeOfString:@"DISCOVERED ELEVATOR #1"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor blueColor];
            }
            
            if (!([logMessage rangeOfString:@"CONNECTED TO ELEVATOR #1"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor blueColor];
                self.elevatorYLinkStatusLabel.text = @"Conn Elev #1";
                self.elevatorYLinkStatusLabel.textColor = [UIColor blueColor];
                
            }
            
            if (!([logMessage rangeOfString:@"DISCOVERED ELEVATOR #2"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor orangeColor];
            }
            
            if (!([logMessage rangeOfString:@"CONNECTED TO ELEVATOR #2"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor orangeColor];
                self.elevatorYLinkStatusLabel.text = @"Conn Elev #2";
                self.elevatorYLinkStatusLabel.textColor = [UIColor orangeColor];
                
            }
            
            if (!([logMessage rangeOfString:@"DISCOVERED ELEVATOR #3"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor purpleColor];
            }
            
            if (!([logMessage rangeOfString:@"CONNECTED TO ELEVATOR #3"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor purpleColor];
                self.elevatorYLinkStatusLabel.text = @"Conn Elev #3";
                self.elevatorYLinkStatusLabel.textColor = [UIColor purpleColor];
                
            }
            
            if (!([logMessage rangeOfString:@"DISCOVERED ELEVATOR #4"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor yellowColor];
            }
            if (!([logMessage rangeOfString:@"CONNECTED TO ELEVATOR #4"].location == NSNotFound)) {
                cell.textLabel.textColor = [UIColor yellowColor];
                self.elevatorYLinkStatusLabel.text = @"Conn Elev #4";
                self.elevatorYLinkStatusLabel.textColor = [UIColor yellowColor];
                
            }
        }
    }
    
    if (! foundLogMessage) {
        cell.textLabel.text = @"";
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE_IN_CONSOLE];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor blackColor];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 14;
}



#pragma mark - actions

- (IBAction)switchToMPEngine:(id)sender {
    
    DLog(@"Switching to SP");
    
    NSMutableString *infoText = [NSMutableString stringWithString:@"Currently engine is: \n"];
    
    if ([[YKSDebugManager sharedManager] isEngineBeaconEnabled]) {
        [infoText appendString:@"Beacon-based MP\n"];
    }
    else {
        [infoText appendString:@"MP Engine Forced"];
    }
    
    [infoText appendString:@"\nEngine switch options:"];
    
    self.switchEngineAlertController = [UIAlertController alertControllerWithTitle:infoText message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *forceSPAction = [UIAlertAction actionWithTitle:@"Force SP Engine" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        YKSDebugConsoleViewController *dbgConsole = self;
        
        DLog(@"Force SP pressed");
        [self.switchEngineAlertController dismissViewControllerAnimated:YES completion:nil];
         
        [[YKSDebugManager sharedManager] switchEngineToSP];
        [dbgConsole doneTap:nil];
    }];
    
    UIAlertAction *beaconBasedAction = [UIAlertAction actionWithTitle:@"Beacon based Engine" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        YKSDebugConsoleViewController *dbgConsole = self;
        
        DLog(@"bacon based pressed");
        
        [self.switchEngineAlertController dismissViewControllerAnimated:YES completion:nil];
        
        [[YKSDebugManager sharedManager] switchEngineBeaconBased];
        [dbgConsole doneTap:nil];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        DLog(@"Cancel pressed");
        [self.switchEngineAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.switchEngineAlertController addAction:forceSPAction];
    [self.switchEngineAlertController addAction:beaconBasedAction];
    [self.switchEngineAlertController addAction:cancelAction];
    
    [self presentViewController:self.switchEngineAlertController animated:YES completion:nil];
}


//TODO: Fix pause logs
- (IBAction)pause:(id)sender {
    
    BOOL isScrollingPaused = [YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController;

    if (isScrollingPaused) {
        // Currently paused, will resume
        
        [[YKSDebugManager sharedManager] shouldPauseLogsToDebugConsole:NO];
        
        [(UIButton *)sender setTitle:PAUSE_AUTO_SCROLL forState:UIControlStateNormal];
        [(UIButton *)sender setTitleColor:self.activeColor forState:UIControlStateNormal];
    }
    else {
        // Currently not paused, will pause
        [[YKSDebugManager sharedManager] shouldPauseLogsToDebugConsole:YES];
        
        [(UIButton *)sender setTitle:RESUME_AUTO_SCROLL forState:UIControlStateNormal];
        [(UIButton *)sender setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    
}


- (IBAction)moreOptionsRestartSessionOrShare:(id)sender {
    
    NSString *plRoomAuthMode = [NSString stringWithFormat:@"Change PL_Room_Auth Mode"];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose an action to do with the BLE Reporter"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Restart Session", @"Share Full Logs", plRoomAuthMode, nil];
    
    actionSheet.tag = kShareASTag;
    [actionSheet showInView:self.view];
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
    
    NSError *deleteError;
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    BOOL isDeleted = [fileMan removeItemAtURL:self.fullSessionLogsZipFileURL error:&deleteError];
    
    if (isDeleted) {
        [[YKSDebugManager sharedManager] logMessage:@"Temporaray Full session logs ZIP file was deleted with success" withErrorLevel:YKSErrorLevelDebug andType:YKSLogMessageTypeService];
    }
    
    if (deleteError) {
        [[YKSDebugManager sharedManager] logMessage:@"Error while deleting temporaray Full session logs ZIP file" withErrorLevel:YKSErrorLevelError andType:YKSLogMessageTypeService];
    }
}


#pragma mark - Sharing debug files

- (void) shareFullSessionLogsZipfile:(NSString*) selectedFileName {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *docDir = [paths objectAtIndex:0];
    NSString* dateTimeStampUsed = [selectedFileName substringWithRange:NSMakeRange(5, 19)];
    NSString *fullSessionLogsZipFileName = [NSString stringWithFormat:@"FullSessionLogs %@.zip", dateTimeStampUsed];
    
    NSString *fullSessionLogsZipFilePath = [docDir stringByAppendingPathComponent:fullSessionLogsZipFileName];
    self.fullSessionLogsZipFileURL = [[NSURL alloc] initFileURLWithPath:fullSessionLogsZipFilePath];
    
    NSArray* inputPaths = [NSArray arrayWithObjects:[docDir stringByAppendingPathComponent:selectedFileName], nil];
    
    [SSZipArchive createZipFileAtPath:fullSessionLogsZipFilePath withFilesAtPaths:inputPaths];
    
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:self.fullSessionLogsZipFileURL];
    self.docController.delegate = self;
    [self.docController setName:[NSString stringWithFormat:@"Full session Logs - %@", dateTimeStampUsed]];
    [self.docController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES];
    }


- (void)shareBLETriangle:(NSString*) selectedFileName  {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString* filePath =  [[paths objectAtIndex:0] stringByAppendingPathComponent:selectedFileName];
    
    NSURL* fileToShareURL = [NSURL fileURLWithPath:filePath];
    
    //    NSString* fileNameActivityItem = [selectedFileName stringByAppendingString:@".csv"];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]
                                            initWithActivityItems:@[selectedFileName, fileToShareURL]
                                            applicationActivities:nil];
    
    [activityVC setValue:[NSString stringWithString:selectedFileName] forKey:@"subject"];
    
    [activityVC setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
    }];
    
    [self presentViewController:activityVC animated:YES completion:^{
    }];
}


- (void) shareFullSessionLogsFiles {
    
    [[YKSFileLogger sharedInstance] addCurrentFullSessionLogsToCurrentFile];
    [[YKSFileLogger sharedInstance] cleanBuffer];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                      [paths objectAtIndex:0] error:nil];
    NSArray *filesWithSelectedPrefixFullLogs = [files filteredArrayUsingPredicate:
                                                [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'Full '"]];
    
    filesWithSelectedPrefixFullLogs = [[filesWithSelectedPrefixFullLogs reverseObjectEnumerator] allObjects];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    for (NSString* fileName in filesWithSelectedPrefixFullLogs) {
        [actionSheet addButtonWithTitle:fileName];
    }
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    
    actionSheet.tag = kShareFullSessionLogsFileASTag;
    
    [actionSheet showInView:self.view];
}



- (void)setPLRoomAuthMode {

    NSUInteger index = 0;
    NSDictionary *plRoomAuthDic = [YBLEManager plRoomAuth_Modes_Dictionary];
    NSMutableArray *plRoomAuthModesList = [NSMutableArray arrayWithCapacity:plRoomAuthDic.count];
    while (index < plRoomAuthDic.count) {
        [plRoomAuthModesList setObject:plRoomAuthDic[@(index)] atIndexedSubscript:index];
        index++;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Available Modes:"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    for (NSString *title in plRoomAuthModesList) {
        [actionSheet addButtonWithTitle:title];
    }
    
    [actionSheet addButtonWithTitle:@"Cancel"];
    // last position:
    actionSheet.cancelButtonIndex = plRoomAuthModesList.count;
    
    actionSheet.tag = kASTagPLRoomAuthModes;
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == kShareASTag) {
        
        if (0 == buttonIndex) {
            
            UIAlertView *av;
            
            av = [[UIAlertView alloc] initWithTitle:@"Restart session" message:@"\nCreate a new session?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
            
            av.tag = kRestartSessionAVTag;
            [av show];
        }
        else if (1 == buttonIndex) {
            [self shareFullSessionLogsFiles];
        }
        else if (2 == buttonIndex) {
            [self setPLRoomAuthMode];
        }

    }
    else if (actionSheet.tag == kSettingsASTag) {
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            // Set Custom yMAN Connection Timeout
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"yMAN Connection Timeout" message:@"Set your custom value (0.5 - 60 sec)" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"SET", nil];
            av.alertViewStyle = UIAlertViewStylePlainTextInput;
            av.tag = kYMANAVTag;
            [[av textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
            [av show];
        }
        else  if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
            // Toggle Elevator Scanning
            BOOL scan = [YBLEManager sharedManager].scanForElevator;
            [YBLEManager sharedManager].scanForElevator = !scan;
            
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Elevator RSSI Threshold" message:@"Set your custom value (0 to 120, minus will be applied)" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"SET", nil];
            av.alertViewStyle = UIAlertViewStylePlainTextInput;
            av.tag = kElevatorAVTag;
            [[av textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDecimalPad];
            [av show];
            
        }
    }
    else if(kShareBLETriangleASTag == actionSheet.tag) {
        
        if (buttonIndex == actionSheet.cancelButtonIndex) {
//            CLS_LOG(@"Cancel pressed");
        }
        else {
            [self shareBLETriangle:[actionSheet buttonTitleAtIndex:buttonIndex]];
        }
        
    }
    else if (kShareFullSessionLogsFileASTag == actionSheet.tag){
        if (buttonIndex == actionSheet.cancelButtonIndex) {
//            CLS_LOG(@"Cancel pressed");
        } else {
            [self shareFullSessionLogsZipfile:[actionSheet buttonTitleAtIndex:buttonIndex]];
        }
    }
    else if (kASTagPLRoomAuthModes == actionSheet.tag) {
        NSString *message;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            [YBLEManager sharedManager].currentPLRoomAuthMode = buttonIndex;
            message = [NSString stringWithFormat:@"Switched to PL_RoomAuth Mode:\n%@", [YBLEManager plRoomAuth_Modes_Dictionary][@([YBLEManager sharedManager].currentPLRoomAuthMode)]];
        }
    else {
            message = [NSString stringWithFormat:@"Didn't switch.\n\nCurrent PL_RoomAuth Mode:\n%@", [YBLEManager plRoomAuth_Modes_Dictionary][@([YBLEManager sharedManager].currentPLRoomAuthMode)]];
        }
        
        DLog(@"Current PLRoomAuthMode is %@", [YBLEManager plRoomAuth_Modes_Dictionary][@(buttonIndex)]);
        [[YKSLogger sharedLogger] logMessage:message withErrorLevel:YKSErrorLevelWarning andType:YKSLogMessageTypeBLE];
    }
    else {
//        CLS_LOG(@"WARNING: Unknown action sheet tag: %li", (long)actionSheet.tag);
    }
}




#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    CLS_LOG(@"Alert view clicked: %li", (long)buttonIndex);
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        if (alertView.tag == kElevatorAVTag){
            
            UITextField * tf = [alertView textFieldAtIndex:0];
            float newValue = tf.text.floatValue;
            if (newValue <= 120 && newValue >= 0) {
                [YBLEManager sharedManager].elevatorRSSIThreshold = -1*newValue;
            }
        }
        else if (alertView.tag == kRestartSessionAVTag){
            [[YBLEManager sharedManager] disconnectFromAllPeripheralsAndExpireGuestAuths];
            
            [[YKSFileLogger sharedInstance] restartStats];
            [[YKSDebugManager sharedManager] clearConnections];
            [[YKSDebugManager sharedManager] clearConsoleLogs];
        }
        else {
            //CLS_LOG(@"Alert view invalid tag: %li", (long)alertView.tag);
        }
    }
}


#pragma mark -

- (void)scrollBLELogTableViewToBottom {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BOOL isScrollingPaused = [YKSDebugManager sharedManager].isLogScrollingPausedInDebugConsoleViewController;
        
        if (! isScrollingPaused) {
        if (self.BLELogTableView.contentSize.height > self.BLELogTableView.frame.size.height) {
            
            CGPoint offset = CGPointMake(0, self.BLELogTableView.contentSize.height - self.BLELogTableView.frame.size.height);
            [self.BLELogTableView setContentOffset:offset animated:YES];
        }
        }
    });
}


#pragma mark - YKSDebugConsoleNewLogsAvailableDelegate

- (void)logsAvailable:(NSArray *)logs {
    
    self.localTemporaryLogMessagesArrayCopy = logs;
    
    
    if (self.isReloadingLogsTableView) {
        
        if (self.isReloadingLogsTableViewsScheduled) {
            //NSLog(@">>>>LOGS>> Skipping Tableviews reloading");
        }
        else {
//            [self performSelector:@selector(callLogsAvailable) withObject:nil afterDelay:0.150];
            self.isReloadingLogsTableViewsScheduled = YES;
            
            //NSLog(@">>>>LOGS>> Scheduled TableViews reloading");
        }
    }
    else {
        
        if (self.isReloadingLogsTableViewsScheduled) {
//            [YKSTablesConnectionsViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(callLogsAvailable) object:nil];
            self.isReloadingLogsTableViewsScheduled = NO;
            
            //NSLog(@">>>>LOGS>> Unscheduled TableViews reloading");
        }
        
        //NSLog(@">>>>LOGS>> Reloading TableViews");
        
        self.isReloadingLogsTableView = YES;
        
        self.localLogMessagesArrayCopy = [NSArray arrayWithArray:self.localTemporaryLogMessagesArrayCopy];
        
        [self.BLELogTableView reloadData];
        [self scrollBLELogTableViewToBottom];
        
        self.isReloadingLogsTableView = NO;
    }
}


- (void)numberOfPrimaryManAvailable:(NSInteger)pYManCount {
    NSString *countString = [NSString stringWithFormat:@"%ld", (long)pYManCount];
    
    self.yManCounterLabel.text = countString;
}


- (void)startedScanningForPrimaryYMan {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.yManCounterLabel.hidden = NO;
        self.yManScanGestureRecognizerView.hidden = NO;
        self.yManScanProgressIndicator.hidden = NO;
        self.yManStaticLabel.hidden = NO;
        
        [self.yManScanProgressIndicator startAnimating];
    });
}


- (void)stoppedScanningForPrimaryYMan {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.yManScanProgressIndicator stopAnimating];
        self.yManScanProgressIndicator.hidden = YES;
    });
}


#pragma mark -

- (void)showStationaryOutsideMessage {
    
    if ([self isDeviceStationary] || [self isOutsideIBeaconRegion]) {
        self.elevatorYLinkStatusLabel.hidden = YES;
        self.elevatorYLinkConnectDot.hidden = YES;
        self.elevatorLabel.hidden = YES;
        self.elevatorScanProgressIndicator.hidden = YES;
        [self.elevatorScanProgressIndicator stopAnimating];
        
        [self.stationaryOutsideStatusLabel setHidden:NO];
    }
    else if (![self isDeviceStationary] && ![self isOutsideIBeaconRegion]) {
        self.elevatorYLinkStatusLabel.hidden = NO;
        // let the elevator make visible the connection dot
        self.elevatorLabel.hidden = NO;
        [self.elevatorScanProgressIndicator startAnimating];
        self.elevatorScanProgressIndicator.hidden = NO;
        
        [self.stationaryOutsideStatusLabel setHidden:YES];
    }
    
    
    if ([self isDeviceStationary] && [self isOutsideIBeaconRegion]) {
        self.stationaryOutsideStatusLabel.text = @"You are outside iBeacon range\nand your device is stationary.\nMove to start scanning";
    }
    else if ([self isDeviceStationary]) {
        self.stationaryOutsideStatusLabel.text = @"Device is stationary,\nMove to start scanning.";
    }
    else if ([self isOutsideIBeaconRegion]) {
        self.stationaryOutsideStatusLabel.text = @"You are outside iBeacon range.";
    } else {
        self.stationaryOutsideStatusLabel.text = @"";
    }
}



-(void)informationUpdated:(NSString *)description {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.yManStatusLabel.text = description;
//    });
}

- (void)yLinkUpdate:(NSString *)update {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.yLinkStatusLabel.text = update;
//    });
}

- (void)elevatorYLinkUpdate:(NSString *)update {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.elevatorYLinkStatusLabel.text = update;
        self.elevatorYLinkStatusLabel.textColor = self.yLinkStatusDefaultTextColor;
    });
}


-(void)foundYMEN:(NSString *)description {

//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.yManInfoLabel.text = description;
//        self.yManInfoLabel.hidden = NO;
//    });
}

#pragma mark - Elevator activity

-(void)connectedToDevice:(NSString *)name {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([name isEqualToString:kDeviceElevatorYLink]) {
            // green dot
            self.elevatorYLinkConnectDot.hidden = NO;
            
            // override to label
            [self addOverrideToElevatorLabel];
            
            // elevator status label
            self.elevatorYLinkStatusLabel.text = @"Connected";
            self.elevatorYLinkStatusLabel.textColor = self.yLinkStatusDefaultTextColor;
            
            // activity indicator
            self.elevatorScanProgressIndicator.hidden = YES;
            [self.elevatorScanProgressIndicator stopAnimating];
        }
    });
}


-(void)disconnectedFromPeripheral:(NSString *)name {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([name isEqualToString:kDeviceElevatorYLink]) {
            // green dot
            self.elevatorYLinkConnectDot.hidden = YES;
            
            // override to label
            [self removeElevatorOverrideLabel];
            
            // elevator status label
            self.elevatorYLinkStatusLabel.text = @"Disconnected";
            self.elevatorYLinkStatusLabel.textColor = self.yLinkStatusDefaultTextColor;
            
            // activity indicator
            self.elevatorScanProgressIndicator.hidden = YES;
            [self.elevatorScanProgressIndicator stopAnimating];
        }
    });

}

-(void)scanningForDevice:(NSString *)name {

    dispatch_async(dispatch_get_main_queue(), ^{

        if ([name isEqualToString:kDeviceElevatorYLink]) {
            // green dot
            self.elevatorYLinkConnectDot.hidden = YES;
            
            // override to label
            [self addOverrideToElevatorLabel];
            
            // elevator status label
            self.elevatorYLinkStatusLabel.text = @"Scanning";
            self.elevatorYLinkStatusLabel.textColor = self.yLinkStatusDefaultTextColor;
            
            // activity indicator
            [self.elevatorScanProgressIndicator startAnimating];
            self.elevatorScanProgressIndicator.hidden = NO;
        }
    });
}

#pragma mark -

- (void)addOverrideToElevatorLabel {
    if (!self.elevatorTapRecognizer) {
        
        self.elevatorTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(elevatorOverrideTapped)];
        
    }
    
    self.elevatorYLinkStatusLabel.userInteractionEnabled = YES;
    [self.elevatorYLinkStatusLabel addGestureRecognizer:self.elevatorTapRecognizer];
}


- (void)removeElevatorOverrideLabel {
    [self.elevatorYLinkStatusLabel removeGestureRecognizer:self.elevatorTapRecognizer];
    self.elevatorYLinkStatusLabel.userInteractionEnabled = NO;
}


- (void)elevatorOverrideTapped {
//    CLS_LOG(@"Elevator Override");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeElevatorOverrideLabel];
    });
    [[YBLEManager sharedManager] overrideElevatorYLinkTimeout];
}



#pragma mark -

- (NSDateFormatter *)dateFormatterForTimeStamp {
    if (!timeStampDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        timeStampDateFormatter = dateFormatter;
    }
    
    return timeStampDateFormatter;
}

- (NSString*) timeStampForFileName {
    
    return [NSString stringWithFormat:@"%@", [[self dateFormatterForTimeStamp] stringFromDate:[NSDate date]]];
}


#pragma mark - Actions

- (void)tapOnRequiredHardwareView {

    if (0 == [[[YKSRequiredHardwareNotificationCenter sharedCenter] requireHardwareCurrentMessages] count]) {
        // If there are no required hardware messages, don't show popover
        return;
    }
    else if ([self.requiredHardwarePopoverController isPopoverVisible]) {
        [self.requiredHardwarePopoverController dismissPopoverAnimated:YES];
    }
    else
    {
        NSBundle *bundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewStoryboard" bundle:bundle];

        UIViewController *requiredHardwareViewController = [storyboard instantiateViewControllerWithIdentifier:@"RequiredHardwareViewControllerSBID"];
        
        requiredHardwareViewController.preferredContentSize = CGSizeMake(166, 102);
        requiredHardwareViewController.modalPresentationStyle = UIModalPresentationPopover;
        
        CGRect startArrow = CGRectMake(self.notifCenterBellImageView.frame.origin.x,
                                       self.notifCenterBellImageView.frame.origin.y + self.notifCenterBellImageView.frame.size.height + 10,
                                       self.notifCenterBellImageView.frame.size.width,
                                       self.notifCenterBellImageView.frame.size.height);
        
        self.requiredHardwarePopoverController = [[WYPopoverController alloc] initWithContentViewController:requiredHardwareViewController];
        
        self.requiredHardwarePopoverController.theme = [WYPopoverTheme themeForIOS7];
        [self.requiredHardwarePopoverController beginThemeUpdates];
        self.requiredHardwarePopoverController.theme.borderWidth = 6;
        self.requiredHardwarePopoverController.theme.fillTopColor = [UIColor blackColor];
        [self.requiredHardwarePopoverController endThemeUpdates];

        
        
        
        self.requiredHardwarePopoverController.delegate = self;
        [self.requiredHardwarePopoverController presentPopoverFromRect:startArrow inView:self.view permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
    }
}


- (void)tapOnYManGestureRecognizerView {
    
    if ([self.yManListPopoverController isPopoverVisible]) {
        [self.yManListPopoverController dismissPopoverAnimated:YES];
    }
    else {
        NSBundle *bundle = [NSBundle bundleWithURL:[YikesEngineMP sharedEngine].bundleURL];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DebugViewStoryboard" bundle:bundle];
        
        UIViewController *yManListViewControler = [storyboard instantiateViewControllerWithIdentifier:@"YManListViewControllerSBID"];
        
        yManListViewControler.modalPresentationStyle = UIModalPresentationPopover;
        yManListViewControler.preferredContentSize = CGSizeMake(130, 80);
        
        CGRect startArrow = CGRectMake(self.bleTriangleTVC.view.frame.origin.x,
                                       self.bleTriangleTVC.view.frame.size.height + 80,
                                       self.bleTriangleTVC.view.frame.size.width,
                                       self.bleTriangleTVC.view.frame.size.height);
        
        self.yManListPopoverController = [[WYPopoverController alloc] initWithContentViewController:yManListViewControler];
        
        self.yManListPopoverController.theme = [WYPopoverTheme themeForIOS7];
        [self.yManListPopoverController beginThemeUpdates];
        self.yManListPopoverController.theme.borderWidth = 6;
        self.yManListPopoverController.theme.fillTopColor = [UIColor blackColor];
        [self.yManListPopoverController endThemeUpdates];
        
        self.yManListPopoverController.delegate = self;
        [self.yManListPopoverController presentPopoverFromRect:startArrow inView:self.view permittedArrowDirections:WYPopoverArrowDirectionNone animated:YES];
    }
}

#pragma mark - Screen Recording

- (IBAction)startRecording:(id)sender {
    
    RPScreenRecorder *recorder = [RPScreenRecorder sharedRecorder];
    
    self.startRecordingButton.enabled = NO;
    
    if (recorder.isRecording) {
        
        [recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            
            if (! error) {
                
                [self.startRecordingButton setTitle:@"RECORD" forState:UIControlStateNormal];
                
                previewViewController.previewControllerDelegate = self;
                
                [self presentViewController:previewViewController animated:YES completion:^{
                    //
                }];
            }
            
            self.startRecordingButton.enabled = YES;
            
        }];
    }
    else {
        [recorder startRecordingWithMicrophoneEnabled:NO handler:^(NSError * _Nullable error) {
            //TODO: check for errors like
            //UserDeclined
            //Disabled
            //FailedToStart
            //Failed
            //InsufficientStorage
            //Interrupted
            //ContentResize
            
            if (!error) {
                [self.startRecordingButton setTitle:@"STOP" forState:UIControlStateNormal];
            }
            
            self.startRecordingButton.enabled = YES;
        }];

    }
}

#pragma mark - RPPreviewViewControllerDelegate

- (void)previewControllerDidFinish:(RPPreviewViewController *)previewController {
    [previewController dismissViewControllerAnimated:YES completion:^{
        //
    }];
}



#pragma mark - WYPopoverControllerDelegate
- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller
{
    if (controller == self.requiredHardwarePopoverController) {
        self.requiredHardwarePopoverController.delegate = nil;
        self.requiredHardwarePopoverController = nil;
    }
    else if (controller == self.yManListPopoverController) {
        self.yManListPopoverController.delegate = nil;
        self.yManListPopoverController = nil;
    }
    
}


#pragma mark - UIPopoverPresentationControllerDelegate
- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    
}

// Called on the delegate when the popover controller will dismiss the popover. Return NO to prevent the
// dismissal of the view.
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
    return YES;
}

// Called on the delegate when the user has taken action to dismiss the popover. This is not called when the popover is dimissed programatically.
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
}

// -popoverPresentationController:willRepositionPopoverToRect:inView: is called on your delegate when the
// popover may require a different view or rectangle.
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}


#pragma mark -


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneTap:(id)sender {
    [[YKSDebugManager sharedManager] hideDebugView];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"bleConsoleSbEmgSegue"]) {
        self.bleTriangleTVC = [segue destinationViewController];
    }
//    else if ([segue.identifier isEqualToString:@"yManListPopoverSegueID"]) {
//        
//        
//        
//        if ((UILabel*)sender == self.yManCounter) {
//            //
//        } else {
//            //
//        }
//        
//    }
}


@end
