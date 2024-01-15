//
//  YKSLogReporter.m
//  Pods
//
//  Created by Alexandar Dimitrov on 2014-10-03.
//
//

#import "YKSFileLogger.h"
#import "SDiPhoneVersion.h"
#import "YikesBLEConstants.h"
#import "YKSDebugManager.h"
#import "YKSDeviceHelper.h"

@import YikesSharedModel;


NSString *const YKSErrorLevelCriticalErrorString = @"[CRITI ";
NSString *const YKSErrorLevelErrorString         = @"[ERROR ";
NSString *const YKSErrorLevelWarningString       = @"[WARNI ";
NSString *const YKSErrorLevelInfoString          = @"[INFO  ";
NSString *const YKSErrorLevelDebugString         = @"[DEBUG ";

NSString *const YKSLogMessageTypeBLEString       = @"- BLE]";
NSString *const YKSLogMessageTypeAPIString       = @"- API]";
NSString *const YKSLogMessageTypeDeviceString    = @"- DVC]";
NSString *const YKSLogMessageTypeServiceString   = @"- SRV]";


#define NUMBER_OF_LOG_MSGS_TO_SAVE_BUFFER 40

// Number of days to keep log files, for 5 days back, it should be -5
#define NUMBER_OF_DAYS_BACK_IN_TIME_TO_KEEP_LOG_FILES -3

static NSDateFormatter* csvDateFormatter;
static NSDateFormatter* hourDateFormatter;

@interface YKSFileLogger ()

@property (nonatomic, strong) NSString* currentFullLogsFileName;
@property (nonatomic, strong) NSMutableArray *fullSessionLogsArray;
@property (nonatomic, strong) NSFileHandle *fileHandler;
@property (atomic, assign) int logMessagesCounter;

@property dispatch_queue_t serialQueueLogBuffers;

@end


@implementation YKSFileLogger

@synthesize timeStampForAllFileTitles, serialQueueLogBuffers;

+ (YKSFileLogger *)sharedInstance {
    
    static YKSFileLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (id) init {

    self = [super init];

    if (self) {
        serialQueueLogBuffers = dispatch_queue_create("co.yikes.yikesengine.logbuffersqueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


- (void)restartStats {
    
    [self addCurrentFullSessionLogsToCurrentFile];
    
    [self cleanBuffer];
    [self createNewFileName];
    [self openFileForFullSessionLogs];
    
    [self deletePreviousFullSessionLogs];
}


- (void)handleLogin {
    [self cleanBuffer];
    [self createNewFileName];
    [self openFileForFullSessionLogs];
    
    [self deletePreviousFullSessionLogs];
}


- (void)handleLogout {
    [self addCurrentFullSessionLogsToCurrentFile];
    [self cleanBuffer];
}



- (void)createNewFileName {
    self.timeStampForAllFileTitles = [self formattedDateFileStamp:[NSDate date]];
    self.currentFullLogsFileName = [NSString stringWithFormat:@"Full %@.txt", self.timeStampForAllFileTitles];
    self.currentFullLogsFileName = [self.currentFullLogsFileName stringByReplacingOccurrencesOfString:@":" withString:@"-"];
}

- (void)writeIPhoneModelToFullLogs {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    DLog(@"Devices name: %@", [self deviceModel]);
    
    NSString* iPhoneDescMsg = [NSString stringWithFormat:@"GA running on: %@\n", [self deviceModel]];
    
    [self.fullSessionLogsArray addObject:iPhoneDescMsg];
    
}


- (NSString*) deviceModel {
    
    NSString* deviceDesc = @"Unknown";
    DeviceVersion devVers = [SDiPhoneVersion deviceVersion];
    
    if (devVers == iPhone4) {
        deviceDesc = @"iPhone 4";
    }
    else if (devVers == iPhone4S) {
        deviceDesc = @"iPhone 4S";
    }
    else if (devVers == iPhone5) {
        deviceDesc = @"iPhone 5";
    }
    else if (devVers == iPhone5C) {
        deviceDesc = @"iPhone 5C";
    }
    else if (devVers == iPhone5S) {
        deviceDesc = @"iPhone 5S";
    }
    else if (devVers == iPhone6) {
        deviceDesc = @"iPhone 6";
    }
    else if (devVers == iPhone6Plus) {
        deviceDesc = @"iPhone 6 Plus";
    }
    else if (devVers == Simulator) {
        deviceDesc = @"Simulator";
    }
    
    return deviceDesc;
}


- (void)writeGAVersionToFullLogs {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    NSString *gaVersionNumber = [NSString stringWithFormat:@"GA v%@ build %@\n", [YKSDeviceHelper guestAppVersion], [YKSDeviceHelper guestAppBuild]];
    [self.fullSessionLogsArray addObject:gaVersionNumber];
    
}



- (void)writeiOSVersionToFullLogs {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    NSString* sysVer = [[UIDevice currentDevice] systemVersion];
    NSString* iOSVer = [NSString stringWithFormat:@"iOS version: %@\n", sysVer];
    
    [self.fullSessionLogsArray addObject:iOSVer];
    
}


- (void)deletePreviousFullSessionLogs {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueLogBuffers, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                          [paths objectAtIndex:0] error:nil];
        NSArray *filesWithSelectedPrefix = [files filteredArrayUsingPredicate:
                                            [NSPredicate predicateWithFormat:@"(self BEGINSWITH[cd] 'Full ') OR (self BEGINSWITH[cd] 'BLE ')"]];
        
        NSError* error = nil;
        
        DLog(@"Files with prefix:\n%@", filesWithSelectedPrefix);
        
        NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[filesWithSelectedPrefix count]];
        
        for (NSString* fileName in filesWithSelectedPrefix) {
            
            NSString *fileNamePath = [NSString stringWithFormat:@"%@/%@",[paths objectAtIndex:0],fileName];
            NSDictionary* properties = [[NSFileManager defaultManager]
                                        attributesOfItemAtPath:fileNamePath
                                        error:&error];
            
            NSDate* creationDate = [properties objectForKey:NSFileCreationDate];
            
            if(error == nil)
            {
                [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                               fileName, @"path",
                                               creationDate, @"creationDate",
                                               nil]];
            }else{
                DLog(@"%@",[error description]);
            }
        }
        
        NSArray* sortedFiles = [filesAndProperties sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDate *date1 = [obj1 objectForKey:@"creationDate"];
            NSDate *date2 = [obj2 objectForKey:@"creationDate"];
            return [date1 compare:date2];
        }];
        
        DLog(@"sortedFiles: %@", sortedFiles);
        
        NSDate *currentDate = [NSDate date];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setDay:NUMBER_OF_DAYS_BACK_IN_TIME_TO_KEEP_LOG_FILES];
        DLog(@"Current date : %@", currentDate);
        
        NSDate *threeDaysAgo = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:currentDate options:0];
        DLog(@"Three days ago date : %@", threeDaysAgo);
        NSDateComponents *threeDaysAgoDateComp = [[NSCalendar currentCalendar]
                                                  components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:threeDaysAgo];
        
        [threeDaysAgoDateComp setHour:0];
        [threeDaysAgoDateComp setMinute:0];
        [threeDaysAgoDateComp setSecond:0];
        
        threeDaysAgo = [[NSCalendar currentCalendar] dateFromComponents:threeDaysAgoDateComp];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        DLog(@"Three days ago new date : %@", threeDaysAgo);
        
        for (NSDictionary* oneFileAndProps in sortedFiles) {
            
            NSDate *creationDate = oneFileAndProps[@"creationDate"];
            
            if (NSOrderedDescending == [threeDaysAgo compare:creationDate]) {
                
                DLog(@"Should delete file %@ with creationDate: %@", oneFileAndProps[@"path"], oneFileAndProps[@"creationDate"]);
                
                NSString* fileName = oneFileAndProps[@"path"];
                
                BOOL isDeleted = [fileManager removeItemAtPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:fileName] error:nil];
                
                if (!isDeleted) {
                    DLog(@"ERROR: Couldn't delete file: %@", fileName);
                }
                else {
                    DLog(@"Just removed file %@", fileName);
                }
            }
        }
    });
}



#pragma mark -

- (void)logToFileAMessage:(NSString*)message
           withErrorLevel:(YKSErrorLevel)errorLevel
        andLogMessageType:(YKSLogMessageType)logMessageType {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(serialQueueLogBuffers, ^{
        
        NSString *formattedLogMessage = [self formattedMessageWithMessage:message errorLevel:errorLevel andType:logMessageType];
        
        [self.fullSessionLogsArray addObject:formattedLogMessage];
        
        self.logMessagesCounter++;
        
        if (NUMBER_OF_LOG_MSGS_TO_SAVE_BUFFER <= self.logMessagesCounter) {
            //save to text file
            [self addCurrentFullSessionLogsToCurrentFile];
            [self cleanBuffer];
        }
    });
}


- (NSString *)formattedMessageWithMessage:(NSString *)message
                             errorLevel:(YKSErrorLevel)errorLevel
                                andType:(YKSLogMessageType)logMessageType {
    
    NSMutableString *tempMessage = [NSMutableString string];
    [tempMessage appendString:[[self hourDateFormatter] stringFromDate:[NSDate date]]];
    [tempMessage appendString:@"  "];
    
    switch (errorLevel) {
        case YKSErrorLevelCriticalError:
            [tempMessage appendString:YKSErrorLevelCriticalErrorString];
            break;
            
        case YKSErrorLevelError:
            [tempMessage appendString:YKSErrorLevelErrorString];
            break;
            
        case YKSErrorLevelDebug:
            [tempMessage appendString:YKSErrorLevelDebugString];
            break;
            
        case YKSErrorLevelInfo:
            [tempMessage appendString:YKSErrorLevelInfoString];
            break;
            
        case YKSErrorLevelWarning:
            [tempMessage appendString:YKSErrorLevelWarningString];
            break;
            
        default:
            break;
    }
    
    [tempMessage appendString:@" "];
    
    switch (logMessageType) {
        case YKSLogMessageTypeService:
            [tempMessage appendString:YKSLogMessageTypeServiceString];
            break;
            
        case YKSLogMessageTypeAPI:
            [tempMessage appendString:YKSLogMessageTypeAPIString];
            break;
            
        case YKSLogMessageTypeBLE:
            [tempMessage appendString:YKSLogMessageTypeBLEString];
            break;
            
        case YKSLogMessageTypeDevice:
            [tempMessage appendString:YKSLogMessageTypeDeviceString];
            break;
            
        default:
            break;
    }
    
    [tempMessage appendString:@"  "];
    [tempMessage appendString:message];
    [tempMessage appendString:@"\n"];
    
    return tempMessage;
}


#pragma mark - Writing to files

- (void) addCurrentFullSessionLogsToCurrentFile {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    dispatch_async(serialQueueLogBuffers, ^{
        
        NSString *filePath = [self completeFilePathForFullSessionLogs];
        
        if (filePath) {
            self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
            
            if(!self.fileHandler) {
                [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
                self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
            }
            
            NSMutableString *concatenatedMessagesToWrite = [NSMutableString string];
            
            for (NSString *logMessage in self.fullSessionLogsArray) {
                [concatenatedMessagesToWrite appendString:logMessage];
            }
            
            [self.fileHandler seekToEndOfFile];
            [self.fileHandler writeData:[concatenatedMessagesToWrite dataUsingEncoding:NSUTF8StringEncoding]];
        }
    });
}



- (void)cleanBuffer {

    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }
    
    dispatch_async(serialQueueLogBuffers, ^{
        
        self.fullSessionLogsArray = [[NSMutableArray alloc] init];
        self.logMessagesCounter = 0;
        
        [YKSDebugManager sharedManager].numberOfLinesOfLogMessagesBuffer = 0;
    });
}



#pragma mark - Opening files
- (void)openFileForFullSessionLogs {
    
    if (! [YKSDebugManager sharedManager].isDebugModeEnabled) {
        return;
    }

    
    dispatch_async(self.serialQueueLogBuffers, ^{
        
        NSURL *fullSessionLogFileURL = [NSURL fileURLWithPath:[self completeFilePathForFullSessionLogs]];
        self.fileHandler = [NSFileHandle fileHandleForUpdatingURL:fullSessionLogFileURL error:nil];
        
        if(!self.fileHandler) {
            NSString *path = [self completeFilePathForFullSessionLogs];
            [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
            NSError *error;
            self.fileHandler = [NSFileHandle fileHandleForUpdatingURL:[NSURL fileURLWithPath:path] error:&error];
            if (!self.fileHandler) {
                DLog(@"WARNING: fileHandler for full session logs was nil!");
            }
        }
        
        NSMutableString *fileName = [NSMutableString stringWithString:@"Full session logs path and filename: "];
        [fileName appendString:[self completeFilePathForFullSessionLogs]];
        [fileName appendString:@"\n\n"];
        
        [self.fullSessionLogsArray addObject:fileName];
        
        
        [self writeIPhoneModelToFullLogs];
        [self writeGAVersionToFullLogs];
        [self writeiOSVersionToFullLogs];
        
        [self.fullSessionLogsArray addObject:@"\n"];
        
        NSMutableString *startLogsMessage = [NSMutableString stringWithString:@"Full session logs started at "];
        [startLogsMessage appendString:[[self csvDateFormatter] stringFromDate:[NSDate date]]];
        [startLogsMessage appendString:@"\n\n"];
        
        [self.fullSessionLogsArray addObject:startLogsMessage];
    });
}


#pragma mark - File paths
- (NSString *)completeFilePathForFullSessionLogs {
    
    if (self.currentFullLogsFileName && self.currentFullLogsFileName.length) {
        NSString *path = [[self docDirPath] stringByAppendingPathComponent:self.currentFullLogsFileName];
        return path;
    }
    
    return nil;
}

- (NSString *)docDirPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}


#pragma mark - date formatters

- (NSString*) formattedDateFileStamp:(NSDate*)currentDate {
    
    if (currentDate) {
        NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormat setTimeZone:localTimeZone];
        
        return [dateFormat stringFromDate:currentDate];
    } else {
        return @"Error: No current date!";
    }
}

- (NSDateFormatter *)csvDateFormatter {
    if (!csvDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd@HH:mm:ss.SSS"];
        csvDateFormatter = dateFormatter;
    }
    
    return csvDateFormatter;
}


- (NSDateFormatter *)hourDateFormatter {
    if (!hourDateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd  HH:mm:ss.SSS"];
        hourDateFormatter = dateFormatter;
    }
    
    return hourDateFormatter;
}


@end
