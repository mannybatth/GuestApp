//
//  YKSDashboardCardVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSDashboardCardVC.h"
#import "IndicatorView.h"
#import "M13BadgeView.h"
#import "YKSDashboardCardOptionsVC.h"
#import "DateHelper.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define ACCESSDOOR_UI_TEST 0 //used to test access door UI before yCentral gives us any

@interface StayUpdateTimerTarget : NSObject
@property(weak, nonatomic) id realTarget;
@end

@implementation StayUpdateTimerTarget

- (void)updateStayStatusDisplay:(NSTimer *)theTimer
{
    [self.realTarget performSelector:@selector(updateStayStatusDisplay)];
}

- (void)updateCheckinAndCheckoutLabels:(NSTimer *)theTimer
{
    [self.realTarget performSelector:@selector(updateCheckinAndCheckoutLabels)];
}

@end


@interface YKSDashboardCardVC ()

@property (strong, nonatomic) UIColor * defaultRoomNumberColor;
@property (nonatomic) CGFloat defaultHotelTitleCenterYPos;

@property (nonatomic, strong) NSArray * accessDoors;

@property (nonatomic, strong) NSTimer * stayStatusUpdateTimer;
@property (nonatomic, strong) NSTimer * checkinCheckoutLabelTimer;
@property (nonatomic, strong) NSSet * missingServices;

@property (nonatomic, strong) YKSDashboardCardOptionsVC *optionsVC;

@end

@implementation YKSDashboardCardVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view.layer setShadowOffset:CGSizeMake(0, 20)];
    [self.view.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [self.view.layer setShadowRadius:15.0];
    [self.view.layer setShadowOpacity:0.8];
    [self.view.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.view.bounds].CGPath];
    
    //Adjust Amenities container so that it's just under the "Dashboard" label
    //Not done in storyboard since it would be a pain to work with other elements behind.
    self.amenitiesTopConstraint.constant = 0; //15
    self.amenitiesBottomConstraint.constant = 0;
    
    self.defaultRoomNumberColor = self.roomNumberLabel.textColor;
    
    [self.roomConnectionView.button setTitle:@"" forState:UIControlStateNormal];
    self.roomConnectionView.outerCircleRadius = 92;
    self.roomConnectionView.innerCircleRadius = 80;
    
    self.defaultHotelTitleCenterYPos = self.hotelTitleLabel.center.y;
    
    self.stayStatusButton.titleLabel.numberOfLines = 0;
    self.stayStatusButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.stayStatusButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self updateStayStatusDisplay];
    [self startStayStatusUpdateTimer];
    [self scheduleCheckinAndCheckoutLabelUpdate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupView];
}


- (void)dealloc {
    [self stopStayStatusUpdateTimer];
    [self stopCheckinCheckoutLabelTimer];
}

- (void)setupView {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    for (YKSStayInfo *stayInfo in user.stays) {
        if ([stayInfo isEqual:self.stay]) {
            self.stay = stayInfo;
        }
    }
    
    YKSStayInfo *stay = self.stay;
    
    
    // TEMP: Need to be removed when hotel branding is in production
    NSString *modifiedHotelName = [self.stay.hotelName stringByReplacingOccurrencesOfString:@" by yikes"
                                                                                 withString:@""];
    
    [self adjustHotelTitleLabelWithText:modifiedHotelName];
    [self processHotelAssets];
    
    NSUInteger nightsLeft = stay.numberOfNightsLeft;
    NSUInteger totalNights = stay.numberOfNights;
    
    self.numberOfNightsLabel.text = [NSString stringWithFormat:@"%@", @(nightsLeft)];
    
    if (nightsLeft == totalNights) {
        self.nightsLabel.text = [NSString stringWithFormat:@"night%@", (nightsLeft == 1) ? @"" : @"s"];
    } else {
        self.nightsLabel.text = [NSString stringWithFormat:@"night%@ left", (nightsLeft == 1) ? @"" : @"s"];
    }
    
    self.roomNumberLabel.text = stay.roomNumber;
    
    [self updateCheckinAndCheckoutLabels];
    
    // update connection status
    if ([[YikesEngine sharedEngine] isInsideHotel]) {
        [self handleRoomEvent:stay.connectionStatus forRoomNumber:stay.roomNumber];
        
        BOOL atLeastOneConnectedAmenity = NO;
        BOOL atLeastOneConnectingAmenity = NO;
        BOOL atLeastOneScanningAmenity = NO;
        
        for (YKSAmenityInfo *amenity in stay.amenities) {
            [self.amenityVC handleRoomEvent:amenity.connectionStatus forRoomNumber:amenity.name];
            
            atLeastOneConnectedAmenity |= (amenity.connectionStatus == kYKSConnectionStatusConnectedToDoor);
            atLeastOneConnectingAmenity |= (amenity.connectionStatus == kYKSConnectionStatusConnectingToDoor);
            atLeastOneScanningAmenity |= (amenity.connectionStatus == kYKSConnectionStatusScanningForDoor);
        }
        
        // Give highest priority to connected state in UI
        if (atLeastOneConnectedAmenity) {
            [self.amenityVC.amenitiesConnectionView setStatus:kYKSConnectionStatusConnectedToDoor];
        }
        else if (atLeastOneConnectingAmenity) {
            [self.amenityVC.amenitiesConnectionView setStatus:kYKSConnectionStatusConnectingToDoor];
        }
        else if (atLeastOneScanningAmenity) {
            [self.amenityVC.amenitiesConnectionView setStatus:kYKSConnectionStatusScanningForDoor];
        }
        else {
            [self.amenityVC.amenitiesConnectionView setStatus:kYKSConnectionStatusDisconnectedFromDoor];
        }
        
        
    } else {
        [self handleEvent:[[YikesEngine sharedEngine] currentLocationState]];
        [self.amenityVC handleEvent:[[YikesEngine sharedEngine] currentLocationState]];
    }
    
    if (stay.roomNumber == nil) {
        
        self.roomNumberLabel.hidden = YES;
        self.roomNumberCaptionLabel.hidden = YES;
        self.roomNotAssignedLabel.hidden = NO;
        
    } else {
        
        self.roomNumberLabel.hidden = NO;
        self.roomNumberCaptionLabel.hidden = NO;
        self.roomNotAssignedLabel.hidden = YES;
    }
    
    [self.pageControl setNumberOfPages:user.stays.count];
    self.pageControl.currentPage = self.cardIndex;
    if (user.stays.count == 1) {
        [self.pageControl setHidden:YES];
        [self stopPulsingAnimationForView:self.backArrowButton];
        [self stopPulsingAnimationForView:self.nextArrowButton];
    } else {
        [self.pageControl setHidden:NO];
        
        self.backArrowButton.hidden = YES;
        self.nextArrowButton.hidden = YES;
        if (self.cardIndex == 0) {
            [self startPulsingAnimationForView:self.nextArrowButton];
        } else if (self.cardIndex == self.totalNumOfCards-1) {
            [self startPulsingAnimationForView:self.backArrowButton];
        } else {
            [self startPulsingAnimationForView:self.backArrowButton];
            [self startPulsingAnimationForView:self.nextArrowButton];
        }
    }
    
    if (![self.stay.primaryGuest.email isEqualToString:user.email]) {
        self.sharedKeysCaptionLabel.text = [NSString stringWithFormat:@"key shared by %@ %@", self.stay.primaryGuest.firstName, self.stay.primaryGuest.lastName];
    } else {
        self.sharedKeysCaptionLabel.text = @"";
    }
    
    self.optionsVC.stay = self.stay;

#if ACCESSDOOR_UI_TEST
   
    NSArray * realAndFake = [self.stay.amenities arrayByAddingObjectsFromArray:[self generateFakeAccessDoors]];
    
    [self addAccessDoors:realAndFake];
    
    [self generateFakeStatusChanges];
#else

    [self addAccessDoors:self.stay.amenities];
#endif
    
    
    [self updateAccessDoorIndicatorsWithCompletionBlock:nil];
}

- (void)updateCheckinAndCheckoutLabels {
    

    BOOL isLocalTimezoneSameAsHotel = self.stay.hotelTimezone.secondsFromGMT == [NSTimeZone localTimeZone].secondsFromGMT;
    
    NSString * hotelTimezoneAbbreviated = [self.stay.hotelTimezone localizedName:NSTimeZoneNameStyleShortDaylightSaving locale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
   
    NSString * arrivalDate = [dateFormat stringFromDate:self.stay.arrivalDate];
    NSString * departDate = [dateFormat stringFromDate:self.stay.departDate];

    //Show relative dates if in the same timezone
   
    if (isLocalTimezoneSameAsHotel) {
        
        arrivalDate = [self relativeDateForDate:self.stay.arrivalDate];
        
        if (!arrivalDate) {
            arrivalDate = [dateFormat stringFromDate:self.stay.arrivalDate];
        }
        
        departDate = [self relativeDateForDate:self.stay.departDate];
        
        if (!departDate) {
            departDate = [dateFormat stringFromDate:self.stay.departDate];
        }
        
    }
      
    
    NSString *checkInDateTime = [NSString stringWithFormat:@"%@ %@", arrivalDate, [DateHelper convertTo12HrTimeFrom24HrTime:self.stay.checkInTime]];
    
    NSString *checkOutDateTime = [NSString stringWithFormat:@"%@ %@", departDate, [DateHelper convertTo12HrTimeFrom24HrTime:self.stay.checkOutTime]];
    
    //Append time zone if not the same
    if (!isLocalTimezoneSameAsHotel) {
   
        checkInDateTime = [checkInDateTime stringByAppendingString:[NSString stringWithFormat:@" %@", hotelTimezoneAbbreviated]];
        checkOutDateTime = [checkOutDateTime stringByAppendingString:[NSString stringWithFormat:@" %@", hotelTimezoneAbbreviated]];
    }


    self.checkInDateLabel.text = checkInDateTime;
    self.checkOutDateLabel.text = checkOutDateTime;
 
}

- (NSString *)relativeDateForDate:(NSDate *)date {
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    
    if ([calendar isDateInToday:date]) {
        return @"Today";
    } else if ([calendar isDateInTomorrow:date]) {
        return @"Tomorrow";
    } else if ([calendar isDateInYesterday:date]) {
        return @"Yesterday";
    }
    
    return nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.hotelTitleLabel.center = CGPointMake(self.hotelTitleLabel.center.x, self.defaultHotelTitleCenterYPos);
}

- (void)adjustHotelTitleLabelWithText:(NSString *)text {
    
    UIFont *font = self.hotelTitleLabel.font;
    CGSize size = self.hotelTitleLabel.frame.size;
    self.hotelTitleLabel.text = text;
    
    for (CGFloat maxSize = self.hotelTitleLabel.font.pointSize;
         maxSize >= self.hotelTitleLabel.minimumScaleFactor * self.hotelTitleLabel.font.pointSize;
         maxSize -= 1.f) {
        
        font = [font fontWithSize:maxSize];
        CGSize constraintSize = CGSizeMake(size.width, MAXFLOAT);
        
        CGRect textRect = [self.hotelTitleLabel.text boundingRectWithSize:constraintSize
                                                  options:(NSStringDrawingUsesLineFragmentOrigin)
                                               attributes:@{NSFontAttributeName:font}
                                                  context:nil];
        
        CGSize labelSize = textRect.size;
        
        if (labelSize.height <= size.height) {
            self.hotelTitleLabel.font = font;
            [self.hotelTitleLabel setNeedsLayout];
            break;
        }
    }
    
    // set the font to the minimum size anyway
    self.hotelTitleLabel.font = font;
    [self.hotelTitleLabel setNeedsLayout];
}

- (void)configureTitleView {
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    titleLabel.text = self.navigationItem.title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:27.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 2;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    self.navigationItem.titleView = titleLabel;
    
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:0 forBarMetrics:UIBarMetricsDefault];
}

- (void)processHotelAssets {
    
    NSString *hotelDashboardImageURL = [YKSAssetsHelper hotelDashboardImageURLForStay:self.stay];
    BOOL isNewImage = [YKSAssetsHelper checkIfDashboardImageURLhasChangedForStay:self.stay];
    
    if (isNewImage) {
        self.progressBar.hidden = NO;
        self.progressBarWidthConstraint.constant = 0;
    }
    
    // ######################
    //For testing a local image resource:
//    [self.hotelBgImageView setImage:[UIImage imageNamed:@"AcmeExterior"]];
//    [self.hotelBgImageView setImage:[UIImage imageNamed:@"AcmeBerkshire"]];
//    self.hotelBgImageView.alpha = 1.0;
    //End testing
    // ######################
    
    [self.hotelBgImageView sd_setImageWithURL:[NSURL URLWithString:hotelDashboardImageURL]
                             placeholderImage:[UIImage imageNamed:@"hotel_bg"]
                                      options:0
                                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                         
                                         CGFloat fraction = (float)receivedSize / (float)expectedSize;
                                         CGFloat progress = MAX(0, MIN(fraction, 1.0));
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             self.progressBarWidthConstraint.constant = self.view.frame.size.width * progress;
                                         });
                                      }
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                        
                                        self.progressBar.hidden = YES;
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            self.progressBarWidthConstraint.constant = 0;
                                        });
                                        
                                        if (image && isNewImage) {
                                            self.hotelBgImageView.alpha = 0.0;
                                            [UIView transitionWithView:self.hotelBgImageView
                                                              duration:3.0
                                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                                            animations:^{
                                                                
                                                                [self.hotelBgImageView setImage:image];
                                                                self.hotelBgImageView.alpha = 1.0;
                                                                
                                                            } completion:nil];
                                        }
                                    }];
    
}

- (void)startBackArrowButtonPulse {
    [self startPulsingAnimationForView:self.backArrowButton];
}

- (void)stopBackArrowButtonPulse {
    [self stopPulsingAnimationForView:self.backArrowButton];
}

- (void)startNextArrowButtonPulse {
    [self startPulsingAnimationForView:self.nextArrowButton];
}

- (void)stopNextArrowButtonPulse {
    [self stopPulsingAnimationForView:self.nextArrowButton];
}

- (void)startPulsingAnimationForView:(UIView *)view {
    
    view.hidden = NO;
    if (![view.layer animationForKey:@"opacity"]) {
        [view setAlpha:0.2f];
        
        [UIView animateWithDuration:1.0f
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                         animations:^{
                             [view setAlpha:1.0f];
                         }
                         completion:nil];
    }
}

- (void)stopPulsingAnimationForView:(UIView *)view {
    [view.layer removeAllAnimations];
    view.hidden = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"AmenityVC"]) {
        
        self.amenityVC = segue.destinationViewController;
        self.amenityVC.dashboardCardVC = self;
        
    } else if ([segue.identifier isEqualToString:@"OptionsViewSegue"]) {
        
        self.optionsVC = segue.destinationViewController;
        self.optionsVC.stay = self.stay;
        self.optionsVC.dashCardVC = self;
        
    }
}

- (IBAction)backArrowButtonTouched:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(backArrowButtonTouchedFromCardWithIndex:)]) {
        [self.delegate backArrowButtonTouchedFromCardWithIndex:self.cardIndex];
    }
}

- (IBAction)nextArrowButtonTouched:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nextArrowButtonTouchedFromCardWithIndex:)]) {
        [self.delegate nextArrowButtonTouchedFromCardWithIndex:self.cardIndex];
    }
}

- (void)setExtraShadeAlpha:(CGFloat)alpha inTime:(NSTimeInterval)fadeTime {
    
    [UIView animateWithDuration:fadeTime animations:^{
    
        self.extraShadeView.alpha = alpha;
    }];
    
}

- (void)amenitiesViewHasBeenToggled:(BOOL)isHidden {
    
}

- (IBAction)stayStatusButtonTapped:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"AirplaneModeInfo"];
    [self presentViewController:nc animated:YES completion:nil];
    
}

#pragma mark Pre checking and Post checkin display

- (void)updateStayStatusDisplay {
    
    if (self.missingServices && ([self.missingServices containsObject:@(kYKSBluetoothService)] ||
        [self.missingServices containsObject:@(kYKSInternetConnectionService)]) ) {
        return;
    }
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    if (user != nil) {
    
        YKSStayStatus stayStatus = self.stay.stayStatus;
        
        self.stayStatusButton.enabled = NO;
        if (self.optionsVC) {
            if ([self.stay.userId isEqualToNumber:user.userId]) {
                self.optionsVC.sharedKeysButton.enabled = YES;
            } else {
                self.optionsVC.sharedKeysButton.enabled = NO;
            }
        }
        
        if (stayStatus == kYKSStayStatusCurrent || stayStatus == kYKSStayStatusUnknown) {
            
            self.stayStatusContainer.hidden = YES;
            
        } else if (stayStatus == kYKSStayStatusNotYetStarted) {
            
            self.stayStatusContainer.hidden = NO;
            
            YKSTimeRemaining timeRemaining = [self.stay timeUntilStayBegins:[NSDate date]];
            
            NSString *text = self.stay.roomNumber? @"your room will be available in" : @"your stay will begin in";
            
            [self.stayStatusButton setAttributedTitle:nil forState:UIControlStateNormal];
            [self.stayStatusButton setTitle:[NSString stringWithFormat:@"%@ \n%@", text, [self stringForTimeRemaining:timeRemaining]] forState:UIControlStateNormal];
            
        } else {
        
            self.stayStatusContainer.hidden = NO;
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"thank you for staying with us \nyour room is no longer available"];
            [attrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Thin" size:16.0] range:NSMakeRange(30, 33)];
            [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrStr.length)];
            
            [self.stayStatusButton setAttributedTitle:attrStr forState:UIControlStateNormal];
            
            if (self.optionsVC) {
                self.optionsVC.sharedKeysButton.enabled = NO;
            }
            
        }
    }
    else {
        [[YikesEngine sharedEngine] stopEngineWithSuccess:^{
            //
        }];
        [AppDelegate goToLoginView];
    }
}

- (void)startStayStatusUpdateTimer {
   
    [self stopStayStatusUpdateTimer];
    

    // set clock to current date
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:date];
    
    NSTimeInterval timeSinceLastSecond = date.timeIntervalSince1970 - floor(date.timeIntervalSince1970);
    NSTimeInterval timeToNextMinute = (60 - dateComponents.second) - timeSinceLastSecond;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToNextMinute * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        StayUpdateTimerTarget *timerTarget = [[StayUpdateTimerTarget alloc] init];
        timerTarget.realTarget = self;
        self.stayStatusUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:timerTarget selector:@selector(updateStayStatusDisplay:) userInfo:nil repeats:YES];
    });
    
}

- (void)stopStayStatusUpdateTimer {
    
    if (self.stayStatusUpdateTimer) {
        [self.stayStatusUpdateTimer invalidate];
    }
    
    self.stayStatusUpdateTimer = nil;
}

- (void)scheduleCheckinAndCheckoutLabelUpdate {
  
    if (self.checkinCheckoutLabelTimer) {
        [self.checkinCheckoutLabelTimer invalidate];
    }
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDate * tomorrow = [NSDate date];
    tomorrow = [tomorrow dateByAddingTimeInterval:86400];
    NSDate * midnight = [calendar startOfDayForDate:tomorrow];
    
    NSTimeInterval timeUntilMidnight = [midnight timeIntervalSinceDate:[NSDate date]];
    timeUntilMidnight += 5;
   
    dispatch_async(dispatch_get_main_queue(), ^{
        StayUpdateTimerTarget *timerTarget = [[StayUpdateTimerTarget alloc] init];
        timerTarget.realTarget = self;
        self.checkinCheckoutLabelTimer = [NSTimer scheduledTimerWithTimeInterval:timeUntilMidnight target:timerTarget selector:@selector(updateStayStatusDisplay:) userInfo:nil repeats:NO];
    });
}

- (void)stopCheckinCheckoutLabelTimer {
    
    if (self.checkinCheckoutLabelTimer) {
        [self.checkinCheckoutLabelTimer invalidate];
    }
    
    self.checkinCheckoutLabelTimer = nil;
}

- (void)numberOfSharedKeysDidChange {
    [self.optionsVC updateSharedKeysCountBadge];
}

- (NSString *)stringForTimeRemaining:(YKSTimeRemaining)timeRemaining {
   
    NSString * toReturn;
    
    if (timeRemaining.numberOfDays > 0) {
       
        toReturn = [NSString stringWithFormat:@"%lu days %lu hours", (unsigned long)timeRemaining.numberOfDays, (unsigned long)timeRemaining.numberOfHours];
        
    } else if (timeRemaining.numberOfDays == 0 && timeRemaining.numberOfHours > 3) {
       
        toReturn = [NSString stringWithFormat:@"%lu hours", (unsigned long)timeRemaining.numberOfHours];
        
    } else if (timeRemaining.numberOfHours < 4 && timeRemaining.numberOfHours > 0) {
        
        NSString * minString = timeRemaining.numberOfMinutes + 1 == 1? @"minute" : @"minutes";
        
        toReturn = [NSString stringWithFormat:@"%lu hours %lu %@", (unsigned long)timeRemaining.numberOfHours, (unsigned long)timeRemaining.numberOfMinutes, minString];
     
    } else if (timeRemaining.numberOfHours == 0 && timeRemaining.numberOfMinutes > 1) {
        
        NSString * minString = timeRemaining.numberOfMinutes + 1 == 1? @"minute" : @"minutes";
        
        toReturn = [NSString stringWithFormat:@"%lu %@", (unsigned long)timeRemaining.numberOfMinutes, minString];
    } else if (timeRemaining.numberOfHours == 0 && timeRemaining.numberOfMinutes == 1) {
        
        return @"under a minute";
        
    } else {
        return @"a few moments";
    }
    
    return toReturn;
    
}

- (void)adjustStayStatusBasedOnPhoneSize {
 
    if ([[AppManager sharedInstance] isIPhone4size]) {
       
        //to make it not clash with amenties button
        self.stayStatusContainerTopConstraint.constant = 100;
        
    } else if ([[AppManager sharedInstance] isIPhone5size]) {
      
        //to make spacing even between (banner + amenities button) and (amenities button + room number)
        self.stayStatusContainerTopConstraint.constant = 10;
    }
    
}

#pragma mark Access Door display related methods

//Pass it an array of YKSAmenityInfo objects, it will filter out only access doors
- (void)addAccessDoors:(NSArray *)allAmenityInfoObjects {
    
    if (self.accessDoors) {
        return;
    }
    
    NSMutableArray * accessDoors = [NSMutableArray array];
    
    //Always add an elevator (until we have a way to know whether or not the hotel has any yikes enabled elevators)
    //NSArray * elevatorArray = @[[self generateElevator]];
    //NSArray * amenityObjectsWithElevator = [elevatorArray arrayByAddingObjectsFromArray:allAmenityInfoObjects];
   
    NSUInteger index = 0;
    
    for (YKSAmenityInfo * amenity in allAmenityInfoObjects) {
     
        if ([amenity isAccessDoorOrElevator]) {
          
            CGPoint neutralPosition = [self positionForAccessDoorAtIndex:0];
            
            IndicatorView * view = [[IndicatorView alloc] initWithFrame:CGRectMake(neutralPosition.x, neutralPosition.y, INDICATOR_WIDTH, INDICATOR_HEIGHT)];
         
            [view.button setTitle:amenity.name forState:UIControlStateNormal];
            view.outerCircleRadius = INDICATOR_WIDTH;
            view.innerCircleRadius = 50;
            view.alpha = 0.0;
    
            [view setStatus:amenity.connectionStatus];

            NSDictionary * entry = @{@"view":view, @"amenityInfo":amenity};
           
            [accessDoors addObject:entry];
            
            [self.view insertSubview:view belowSubview:self.extraShadeView];
            
        }
        
        index++;
        
    }
    
    self.accessDoors = [NSArray arrayWithArray:accessDoors];
    
}

- (void)updateAccessDoorIndicatorsWithCompletionBlock:(void (^)(void))completion; {
    
    NSUInteger index = 0;
    
    for (NSDictionary * amenityEntry in self.accessDoors) {
        
        YKSAmenityInfo * amenityInfo = amenityEntry[@"amenityInfo"];
        IndicatorView * view = amenityEntry[@"view"];
       
        if ((amenityInfo.connectionStatus == kYKSConnectionStatusConnectedToDoor ||
            amenityInfo.connectionStatus == kYKSConnectionStatusConnectingToDoor)
            &&
            index < 6) {
          
            CGPoint position = [self positionForAccessDoorAtIndex:index];
            
            if (view.alpha < 1.0) {
                view.frame = CGRectMake(position.x, position.y, INDICATOR_WIDTH, INDICATOR_HEIGHT);
            }
          
            view.finalPoint = position;
            view.finalAlpha = 1.0;
            
            index++;
            
        } else {
           
            view.finalAlpha = 0.0;
            
        }
        
    }
    
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        for (NSDictionary * entry in self.accessDoors){
            
            IndicatorView * view = entry[@"view"];
            
            view.frame = CGRectMake(view.finalPoint.x, view.finalPoint.y, INDICATOR_WIDTH, INDICATOR_HEIGHT);
            view.alpha = view.finalAlpha;
            
        }
        
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
    
}

- (void)replaceAccessDoorsWithNewOnes:(NSArray *)newDoors {
   
    //first set all statuses to disconnected
    for (NSDictionary * amenityEntry in self.accessDoors) {
       
        YKSAmenityInfo * info = amenityEntry[@"amenityInfo"];
        info.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
        
    }
    
    [self updateAccessDoorIndicatorsWithCompletionBlock:^{
  
        [self removeAllAccessDoorIndicators];
        
        [self addAccessDoors:newDoors];
        
        [self updateAccessDoorIndicatorsWithCompletionBlock:nil]; //to show the new ones
        
    
    }];
    
}

- (void)removeAllAccessDoorIndicators {
   
    for (NSDictionary * entry in self.accessDoors) {
   
        IndicatorView * view = entry[@"view"];
//        YKSAmenityInfo * amenity = entry[@"amenityView"];
//        
//        amenity = nil;
        
        [view removeFromSuperview];
        
    }
    
    self.accessDoors = nil;
    
}

- (CGPoint)positionForAccessDoorAtIndex:(NSUInteger)index {
   
    CGPoint startPosition = self.nightsLabel.frame.origin;
    startPosition.x += 12 + index % 3 * (INDICATOR_WIDTH + 8);
    startPosition.y += (index / 3)*(INDICATOR_HEIGHT + 15) + 126;
   
    return CGPointMake(startPosition.x, startPosition.y);
}

- (NSDictionary *)accessDoorEntryForRoomNumber:(NSString *)roomNumber {
   
    for (NSDictionary * entry in self.accessDoors) {
        YKSAmenityInfo * amenity = entry[@"amenityInfo"];
        
        if ([amenity.name isEqualToString:roomNumber]) {
            return entry;
        }
        
    }
    
    return nil;
    
}

- (YKSAmenityInfo *)generateElevator {
  
    NSDictionary * elevatorDict = @{@"name":@"Elevator", @"open_time":@"00:00", @"close_time":@"00:00", @"subtype":@"access"};
    YKSAmenityInfo * elevator = [YKSAmenityInfo newWithJSONDictionary:elevatorDict];
    elevator.connectionStatus = kYKSConnectionStatusDisconnectedFromDoor;
    
    return elevator;
    
}


- (NSArray *)generateFakeAccessDoors  {

  
    NSArray * fakeDoors = @[@"Front Door", @"External Stairs", @"Secret Entrance", @"Rooftop Access", @"Studio Door"];
    
    NSMutableArray * toReturn = [NSMutableArray array];
   
    for (NSString * name in fakeDoors) {
      
        NSDictionary * newAmenity = @{@"name":name, @"open_time":@"10:00", @"close_time":@"12:00", @"subtype":@"access"};
        YKSAmenityInfo * amenity = [YKSAmenityInfo newWithJSONDictionary:newAmenity];
        amenity.connectionStatus = kYKSConnectionStatusConnectingToDoor;

        [toReturn addObject:amenity];
        
    }
    
   
    return [NSArray arrayWithArray:toReturn];
    
}

- (void)generateFakeStatusChanges {
   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleRoomEvent:kYKSConnectionStatusDisconnectedFromDoor forRoomNumber:@"Elevator"];
    });
   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleRoomEvent:kYKSConnectionStatusDisconnectedFromDoor forRoomNumber:@"External Stairs"];

    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleRoomEvent:kYKSConnectionStatusConnectedToDoor forRoomNumber:@"Elevator"];
        //
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleRoomEvent:kYKSConnectionStatusConnectedToDoor forRoomNumber:@"Elevator"];
        [self handleRoomEvent:kYKSConnectionStatusConnectedToDoor forRoomNumber:@"Secret Entrance"];
        [self handleRoomEvent:kYKSConnectionStatusConnectedToDoor forRoomNumber:@"Rooftop Access"];
        [self handleRoomEvent:kYKSConnectionStatusConnectedToDoor forRoomNumber:@"Studio Door"];
        
        //
    });


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(17.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
       
        NSArray * realAndFake = [self.stay.amenities arrayByAddingObjectsFromArray:[self generateFakeAccessDoors]];
       
        [self replaceAccessDoorsWithNewOnes:realAndFake];
        //
    });
}

#pragma mark handler methods to change room number connection status

- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber {
    [self handleRoomEvent:newStatus forRoomNumber:roomNumber disconnectReasonCode:kYKSDisconnectReasonCodeUnknown];
}

- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber disconnectReasonCode:(YKSDisconnectReasonCode)code {
    
    if ([roomNumber isEqualToString:self.stay.roomNumber]) {
        
        IndicatorView * view = self.roomConnectionView;
        [view setStatus:newStatus];
        
        switch (newStatus) {
                
            case kYKSConnectionStatusConnectedToDoor:
                self.roomNumberLabel.textColor = [UIColor whiteColor];
                break;
                
            case kYKSConnectionStatusConnectingToDoor:
                self.roomNumberLabel.textColor = [UIColor whiteColor];
                break;
                
            case kYKSConnectionStatusScanningForDoor:
                self.roomNumberLabel.textColor = self.defaultRoomNumberColor;
                break;
                
            case kYKSConnectionStatusDisconnectedFromDoor:
                self.roomNumberLabel.textColor = self.defaultRoomNumberColor;
                [view handleRoomDisconnectReason:code];
                break;
                
            default:
                break;
        }
        
    } else {
       
        NSDictionary * amenityEntry = [self accessDoorEntryForRoomNumber:roomNumber];
        
        if (!amenityEntry) {
            return;
        }
       
        IndicatorView * view = amenityEntry[@"view"];
        YKSAmenityInfo * info = amenityEntry[@"amenityInfo"];
    
        [view setStatus:newStatus];
        info.connectionStatus = newStatus;
        
        [self updateAccessDoorIndicatorsWithCompletionBlock:nil];
        
        
    }
    
}

- (void)handleEvent:(YKSLocationState)state {
    
    if (state == kYKSLocationStateEnteredMPHotel || state == kYKSLocationStateEnteredSPHotel) {
        if (self.stay.connectionStatus == kYKSConnectionStatusDisconnectedFromDoor) {
            [self.roomConnectionView setState:kAmenityDisplaySolidGrey];
            self.roomNumberLabel.textColor = self.defaultRoomNumberColor;
        }
    } else if (state == kYKSLocationStateLeftMPHotel || state == kYKSLocationStateLeftSPHotel) {
        [self.roomConnectionView setState:kAmenityDisplayEmpty];
        self.roomNumberLabel.textColor = self.defaultRoomNumberColor;
    }
}

- (void)handleRequiredServicesMissing:(NSSet *)missingServices {
    
    self.missingServices = [NSSet setWithSet:missingServices];
    
    if ([missingServices containsObject:@(kYKSBluetoothService)] &&
        [missingServices containsObject:@(kYKSInternetConnectionService)]) {
        
        self.stayStatusContainer.hidden = NO;
        self.stayStatusButton.enabled = YES;
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"if airplane mode is enabled, this app needs to be on screen to unlock doors. tap for more info."];
        [attrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0] range:NSMakeRange(0, attrStr.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrStr.length)];
        
        [self.stayStatusButton setAttributedTitle:attrStr forState:UIControlStateNormal];
    
    } else if ([missingServices containsObject:@(kYKSInternetConnectionService)]) {
        
        self.stayStatusContainer.hidden = NO;
        self.stayStatusButton.enabled = YES;
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"No internet connection found. Enable wifi or cellular data to continue using mobile key."];
        [attrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0] range:NSMakeRange(0, attrStr.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attrStr.length)];
        
        [self.stayStatusButton setAttributedTitle:attrStr forState:UIControlStateNormal];
        
    } else {
        
        [self updateStayStatusDisplay];
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

