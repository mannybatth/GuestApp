//
//  YKSAmenityViewController.m
//  YikesGuestApp
//
//  Created by Elliot Sinyor on 2015-07-10.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSAmenityViewController.h"
#import "YKSDashboardCardVC.h"


#define M_PI 3.14159265358979323846264338327950288

#define AMENITY_UI_TEST 0

@interface YKSAmenityViewController () <IndicatorViewDelegate>

@property (assign) BOOL isShowingAmenityDoors;
@property (strong, nonatomic) NSDictionary * amenityDoors;
@property (assign, nonatomic) CGPoint amenitiesConnectionViewOrigin;
@property (assign, nonatomic) CGFloat halfSquareDistance;
@property (assign, nonatomic) CGPoint circleStartPoint;
@property (strong, nonatomic) UIButton * amenityViewCloseButton;
@property (strong, nonatomic) NSMutableArray * amenityIndicatorViews;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@end

@implementation YKSAmenityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isShowingAmenityDoors = NO;
    
    //Place the "amenities" button so that it appears under the room number
    //circle in the DashboardCardVC
    self.amenitiesConnectionView.outerCircleRadius = 62;
    self.amenitiesConnectionView.innerCircleRadius = 50;
    [self.amenitiesConnectionView.button setTitle:@"amenities" forState:UIControlStateNormal];
    
    [self setupAmenitiesCircle];
    
#if AMENITY_UI_TEST
    [self addTestAmenityDoors];
#else
    [self addDoorDisplays:self.dashboardCardVC.stay.amenities];
#endif
    
    [self updateConnectionViewStatus];
    
    
    self.amenityViewCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.amenityViewCloseButton setImage:[UIImage imageNamed:@"amenities_circle_x"] forState:UIControlStateNormal];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeButtonPushed)];
    [self.view addGestureRecognizer:self.tapRecognizer];

    self.amenityViewCloseButton.alpha = 0.0;
    
    [self.view addSubview:self.amenityViewCloseButton];
}

- (void)updateConnectionViewStatus {
    
    [self.dashboardCardVC.stay.amenities enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(YKSAmenityInfo *amenity, NSUInteger idx, BOOL *stop) {
       
        if (![amenity isAccessDoorOrElevator]) {
            [self updateConnectionViewForAmenityWithName:amenity.name newStatus:amenity.connectionStatus];
            
        }
        
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UITapGestureRecognizer * tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeButtonPushed)];
    [self.amenityViewCloseButton addGestureRecognizer:tapRec];
    
    self.amenitiesConnectionViewTopConstraint.constant = self.dashboardCardVC.roomConnectionView.frame.origin.y + self.dashboardCardVC.roomConnectionView.frame.size.height + 7;
    
    if (self.isShowingAmenityDoors) {
        self.dashboardCardVC.amenitiesBottomConstraint.constant = [self bottomConstraintForAmenityVCWhenOpen];
    }
    else {
        self.dashboardCardVC.amenitiesBottomConstraint.constant = [self bottomConstraintForAmenityVCWhenClosed];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.amenitiesConnectionViewOrigin = self.amenitiesConnectionView.frame.origin;
    
    [self calculateCircleCenter];
    
}

- (void)closeButtonPushed {
   
    [self hideAmenityDoors];
    
}

- (void)setupAmenitiesCircle {
    BOOL hasAssignedRoom = self.dashboardCardVC.stay.roomNumber != nil;
    BOOL isStayCurrent = self.dashboardCardVC.stay.stayStatus == kYKSStayStatusCurrent;
    BOOL isThereAtLeastOneAmenityOpen = NO;
    
    for (YKSAmenityInfo *oneAmenity in self.dashboardCardVC.stay.amenities) {
        if ([oneAmenity isOpenNow]) {
            isThereAtLeastOneAmenityOpen = YES;
            break;
        }
    }
    
    if (hasAssignedRoom) {
        self.amenitiesConnectionView.hidden = NO;
        
        self.amenitiesConnectionView.lockIconImageView.hidden = isStayCurrent && isThereAtLeastOneAmenityOpen;
    }
    else {
        self.amenitiesConnectionView.hidden = YES;
    }
    
}

- (void)indicatorViewButtonPushed:(UIButton *)button {
    
    if (!self.isShowingAmenityDoors) {
        [self showAmenityDoors];
    }
    
}

- (void)calculateCircleCenter {
   
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat startX = 0;
    CGFloat startY = 0;
   
    if (height >= width) {
       
        startX = 0;
        startY = (height - width)/2.0f;
        self.halfSquareDistance = width/2.0f;
        
    } else {
       
        startX = (width - height)/2.0f;
        startY = 0;
        self.halfSquareDistance = height/2.0f;
        
    }
    
    self.circleStartPoint = CGPointMake(startX, startY);
    
}

- (CGPoint)rectangularPositionForElement:(NSInteger)element ofTotal:(NSInteger)total {
   
    //CGFloat totalWidth = self.amenitiesButton.frame.origin.x;
    //CGFloat totalHeight = self.view.frame.size.height;
    
    CGFloat elementWidth = 60;
    CGFloat elementHeight = 60;
    
    CGFloat padding = 15;
  
    NSUInteger xstart = self.amenitiesConnectionView.frame.origin.x - 2*(elementWidth + padding) - 2*padding;
    
    NSUInteger xpos = element % 2;
    NSUInteger ypos = element / 2;
   
    return CGPointMake(xstart + xpos*(elementWidth+2*padding), ypos*(elementHeight + padding));
    
}

//Returns an array of NSValues, each of which can return its value as a CGPoint
- (NSArray *)circularOriginPointsForNumberOfElements:(NSUInteger)total {
 
    
    CGFloat circleRadius = self.amenitiesConnectionView.outerCircleRadius/2.0f;
    //CGFloat circleRadius = 30;
    CGFloat halfHeight = self.halfSquareDistance;
  
    CGFloat hypotenuse;
  
//    hypotenuse = halfHeight *.65;
   
    NSMutableArray * points = [NSMutableArray array];
    
    if (total > 7 && halfHeight > 160) {
       hypotenuse = halfHeight *.78;
        //hypotenuse = halfHeight *.853;
    } else {
        hypotenuse = halfHeight *.8;
    }
    
    
    if (total > 12) {
        total = 12;
    }
    
    switch (total) {
        case 1: {
          
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - circleRadius, halfHeight - circleRadius - hypotenuse)]];
            break;
        }
        case 2: {
            
            CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180
            CGFloat triangle = hypotenuse * sinf(degree);
            CGFloat negativeValue = halfHeight - triangle - circleRadius;
            CGFloat positiveValue = halfHeight + triangle - circleRadius;
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(negativeValue, negativeValue)]];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(positiveValue, negativeValue)]];
            break;
        }
        case 3: {
            CGFloat degree    = M_PI / 3.0f; // = 60 * M_PI / 180
            CGFloat triangleA = hypotenuse * cosf(degree);
            CGFloat triangleB = hypotenuse * sinf(degree);
            
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - triangleB - circleRadius,
                                                                   halfHeight - triangleA - circleRadius)]];
 
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight + triangleB - circleRadius,
                                                                    halfHeight - triangleA - circleRadius)]];
            
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - circleRadius,
                                                                     halfHeight + hypotenuse - circleRadius)]];
            
            
            break;
        }
        case 4: {
            CGFloat degree    = M_PI / 4.0f; // = 45 * M_PI / 180
            CGFloat triangleB = hypotenuse * sinf(degree);
            CGFloat negativeValue = halfHeight - triangleB - circleRadius;
            CGFloat positiveValue = halfHeight + triangleB - circleRadius;
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(negativeValue, negativeValue)]];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(positiveValue, negativeValue)]];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(negativeValue, positiveValue)]];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(positiveValue, positiveValue)]];
            break;
        }
        case 5: {
            CGFloat degree    = M_PI / 2.5f; // = 72 * M_PI / 180
            CGFloat triangleA = hypotenuse * cosf(degree);
            CGFloat triangleB = hypotenuse * sinf(degree);
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - triangleB - circleRadius,
                                                         halfHeight - triangleA - circleRadius)]];
             [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - circleRadius,
                                                         halfHeight - hypotenuse - circleRadius)]];
              [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight + triangleB - circleRadius,
                                                         halfHeight - triangleA - circleRadius)]];
            
            degree    = M_PI / 5.0f;  // = 36 * M_PI / 180
            triangleA = hypotenuse * cosf(degree);
            triangleB = hypotenuse * sinf(degree);
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight - triangleB - circleRadius,
                                                         halfHeight + triangleA - circleRadius)]];
            [points addObject:[NSValue valueWithCGPoint:CGPointMake(halfHeight + triangleB - circleRadius,
                                                         halfHeight + triangleA - circleRadius)]];

            
            break;
        }
        case 0:
            break;
            
        default:
        {
            CGFloat degree = 2.0*M_PI / (float)total;
            CGFloat offset = M_PI / 2.0;
            //CGFloat offset = 0 ;

            
            for (int i = 0; i < total; i++) {
                
                CGPoint point = CGPointMake(halfHeight - circleRadius - hypotenuse*cosf(i*degree + offset), halfHeight - circleRadius - hypotenuse*sinf(i*degree + offset));
                [points addObject:[NSValue valueWithCGPoint:point]];
                
                
            }
            break;
        }
    
    }
    
    
    return [NSArray arrayWithArray:points];
    
}

- (void)addDoorDisplays:(NSArray *)amentityInfoArray {
    
    NSMutableArray * toAdd = [NSMutableArray array];
    for (YKSAmenityInfo * amenityInfo in amentityInfoArray) {
        
        if (![amenityInfo isAccessDoorOrElevator]) {
            [toAdd addObject:amenityInfo];
        }
        
    }
    
    NSArray * allAmenityDoors = [NSArray arrayWithArray:toAdd];
    
    if (allAmenityDoors.count == 0) {
        self.amenitiesConnectionView.hidden = YES;
        return;
    } else {
        self.amenitiesConnectionView.hidden = NO;
    }
    
    NSMutableDictionary * amenityDoors = [NSMutableDictionary dictionary];
   
    
    //Pre-calculate circle points and store each in its own view.
    //This means if the number changes, removeAmenityDoors should be called, and add called again
    

    NSInteger index = 0;
    
    for (YKSAmenityInfo * amenity in allAmenityDoors) {
       
        CGPoint origin = self.amenitiesConnectionView.frame.origin;
    
        IndicatorView * amenityView = [[IndicatorView alloc] initWithFrame:CGRectMake(origin.x, self.amenitiesConnectionViewTopConstraint.constant, 70, 70)];
        
        [amenityView.button setTitle:amenity.name forState:UIControlStateNormal];
        amenityView.outerCircleRadius = 62;
        amenityView.innerCircleRadius = 50;
        amenityView.alpha = 0.0;
        
        [self setupLockIcon:amenity onAmenityView:amenityView];
        
//        DLog(@"Amenity %@:\nopenTime: %@\ncloseTime: %@", amenity.name, amenity.openTime, amenity.closeTime);
        
        [amenityView setStatus:amenity.connectionStatus];
        
        NSDictionary * amenityEntry = @{@"amenityInfo":amenity, @"view":amenityView};
        
        if (amenity.name != nil) {
            [amenityDoors setObject:amenityEntry forKey:amenity.name];
        }
        else {
            CLS_LOG(@"Found an amenity without a name - cannot add it to the list of amenities (name is the key for the dictionary):\n%@", amenity);
        }
        
        [self.view addSubview:amenityView];
        
        
        index++;
    }
    
    self.amenityDoors = [NSDictionary dictionaryWithDictionary:amenityDoors];
    
}

- (void)setupLockIcon:(YKSAmenityInfo *)amenity onAmenityView:(IndicatorView *)amenityView {
    YKSStayInfo *stay = self.dashboardCardVC.stay;
    BOOL hasAssignedRoom = stay.roomNumber != nil;
    BOOL isStayCurrent = stay.stayStatus == kYKSStayStatusCurrent;
    BOOL isAmenityOpen = [amenity isOpenNow];
    
    BOOL hasAccessToAmenity = hasAssignedRoom && isStayCurrent && isAmenityOpen;
    amenityView.lockIconImageView.hidden = hasAccessToAmenity;
}

- (CGFloat)bottomConstraintForAmenityVCWhenClosed {
    
    CGFloat y = self.amenitiesConnectionViewTopConstraint.constant + self.amenitiesConnectionView.frame.size.height;
    return [UIScreen mainScreen].bounds.size.height - y;
    
}

- (CGFloat)bottomConstraintForAmenityVCWhenOpen {
    
    return 72;
    
}

- (void)showAmenityDoors {
    
    if (self.dashboardCardVC && [self.dashboardCardVC respondsToSelector:@selector(amenitiesViewHasBeenToggled:)]) {
        [self.dashboardCardVC amenitiesViewHasBeenToggled:NO];
    }
    
    self.dashboardCardVC.amenitiesBottomConstraint.constant = [self bottomConstraintForAmenityVCWhenOpen];
    
    self.isShowingAmenityDoors = YES;
    
    NSArray * points = [self circularOriginPointsForNumberOfElements:self.amenityDoors.count];
    self.amenityIndicatorViews = [NSMutableArray array];

    
    CGSize buttonSize = self.amenitiesConnectionView.frame.size;
    
    NSUInteger index = 0;
    for (NSDictionary * entry in self.amenityDoors.allValues) {
        
        if (index < points.count) {
            
            IndicatorView * view = entry[@"view"];
            
            NSValue * originValue = (NSValue *)points[index];
            CGPoint origin = [originValue CGPointValue];
            
            //Add offset that takes starting point into account
            
            origin.x += self.circleStartPoint.x;
            origin.y += self.circleStartPoint.y;
            
            view.alpha = 0.0;
            
            view.finalPoint = origin;
            
            YKSAmenityInfo *amenity = entry[@"amenityInfo"];
            [self setupLockIcon:amenity onAmenityView:view];
            
            [self.amenityIndicatorViews addObject:view];
        }
        
        index++;
        
    }
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.view.superview addSubview:self.amenityViewCloseButton];
        
        for (IndicatorView * view in self.amenityIndicatorViews) {
            view.frame = CGRectMake(view.finalPoint.x, view.finalPoint.y, 70, 70);
            view.alpha = 1.0;
            
            [self.view.superview addSubview:view];
            
        }
        
        self.amenitiesConnectionView.frame = CGRectMake(self.circleStartPoint.x + self.halfSquareDistance - buttonSize.height/2.0f,
                                                        self.circleStartPoint.y + self.halfSquareDistance - buttonSize.width/2.0f, buttonSize.width, buttonSize.height);
        
        
        self.amenityViewCloseButton.frame = self.amenitiesConnectionView.frame;
        
        self.amenitiesConnectionView.alpha = 0.0;
        self.amenityViewCloseButton.alpha = 1.0;
        
    } completion:^(BOOL finished) {

    }];
    
    [self.dashboardCardVC setExtraShadeAlpha:0.7 inTime:0.2];
    
}

- (void)hideAmenityDoors {
    
    if (self.dashboardCardVC && [self.dashboardCardVC respondsToSelector:@selector(amenitiesViewHasBeenToggled:)]) {
        [self.dashboardCardVC amenitiesViewHasBeenToggled:YES];
    }
   
    
    [self hideAmenityDoorsWithCompletionBlock:^{
          self.dashboardCardVC.amenitiesBottomConstraint.constant = [self bottomConstraintForAmenityVCWhenClosed];
    }];
    
    self.isShowingAmenityDoors = NO;
    
}

- (void)hideAmenityDoorsWithCompletionBlock:(void (^)(void))completion; {
  
    if (!self.isShowingAmenityDoors) {
        if (completion) {
            completion();
        }
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        
        for (IndicatorView * view in self.amenityIndicatorViews) {
            
            CGPoint origin = self.amenitiesConnectionViewOrigin;
            view.frame = CGRectMake(origin.x, origin.y, 70, 70);
            view.alpha = 0.0;
            
            [view removeFromSuperview];
        }
        
        [self.amenityViewCloseButton removeFromSuperview];
        
        self.amenitiesConnectionView.frame = CGRectMake(self.amenitiesConnectionViewOrigin.x, self.amenitiesConnectionViewOrigin.y, 70, 70);
        self.amenityViewCloseButton.frame = self.amenitiesConnectionView.frame;
        
        self.amenitiesConnectionView.alpha = 1.0;
        self.amenityViewCloseButton.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        self.isShowingAmenityDoors = NO;
        if (completion) {
            completion();
        }
        
    }];
    
    [self.dashboardCardVC setExtraShadeAlpha:0.0 inTime:0.2];

}

- (IndicatorView *)viewForRoomNumber:(NSString *)roomNumber {
   
    NSDictionary * entry = self.amenityDoors[roomNumber];
    
    if (!entry) {
        return nil;
    }
   
    return entry[@"view"];
    
}

- (BOOL)updateConnectionViewForAmenityWithName:(NSString *)name newStatus:(YKSConnectionStatus)newStatus {
    
    IndicatorView * view = [self viewForRoomNumber:name];
    
    if (view) {
        [view setStatus:newStatus];
    }
    
    if (newStatus == kYKSConnectionStatusConnectingToDoor ||
        newStatus == kYKSConnectionStatusConnectedToDoor) {
        
        [self.amenitiesConnectionView.button setTitle:name forState:UIControlStateNormal];
        [self.amenitiesConnectionView setStatus:newStatus];
        
        switch (newStatus) {
                
            case kYKSConnectionStatusConnectedToDoor:
                self.amenitiesConnectionView.button.titleLabel.textColor = [UIColor whiteColor];
                [self.amenitiesConnectionView.button setBackgroundImage:nil forState:UIControlStateNormal];
                break;
                
            case kYKSConnectionStatusConnectingToDoor:
                self.amenitiesConnectionView.button.titleLabel.textColor = [UIColor whiteColor];
                [self.amenitiesConnectionView.button setBackgroundImage:nil forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
        
        return YES;
        
    }
    
    return NO;
}

#pragma mark State changing handler method

- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber {
   
    BOOL isAmenityDoor = NO;
    BOOL foundActiveConnection = NO;
    
    for (YKSAmenityInfo *amenity in self.dashboardCardVC.stay.amenities) {
        
        NSString *amenityName;
        YKSConnectionStatus amenityStatus;
        
        if ([amenity.name isEqualToString:roomNumber] && ![amenity isAccessDoorOrElevator]) {
            
            amenityName = roomNumber;
            amenityStatus = newStatus;
            
            isAmenityDoor = YES;
            
            if ([self updateConnectionViewForAmenityWithName:amenityName newStatus:amenityStatus]) {
                
                foundActiveConnection = YES;
            }
            
        } else {
            
            // TEMP: Needs more work on Engine, Engine is returning objects with non updated connection status
//            amenityName = amenity.name;
//            amenityStatus = amenity.connectionStatus;
            
        }
        
    }
   
    //Only change back to "amenities" if we haven't found an active connection AND the room in question is an amenity door
    if (!foundActiveConnection && isAmenityDoor) {
        
        [self.amenitiesConnectionView.button setTitle:@"amenities" forState:UIControlStateNormal];
        [self.amenitiesConnectionView setState:kAmenityDisplayEmpty];
    }
    
}

- (void)handleEvent:(YKSLocationState)state {
   
    BOOL areAllAmenitiesDisconnected = YES;
   
    for (NSDictionary * entry in self.amenityDoors.allValues) {
        
        IndicatorView * view = entry[@"view"];
        YKSAmenityInfo * amenity = entry[@"amenityInfo"];
        
        if (!view) {
            continue;
        }
        
        if (state == kYKSLocationStateEnteredMPHotel || state == kYKSLocationStateEnteredSPHotel) {
            
            if (amenity.connectionStatus == kYKSConnectionStatusDisconnectedFromDoor) {
                
                [view setState:kAmenityDisplaySolidGrey];
                
            } else { //we are connected to the amenity, do not set the indicator to grey
               
                areAllAmenitiesDisconnected = NO;
                
            }
            
        } else if (state == kYKSLocationStateLeftMPHotel || state == kYKSLocationStateLeftSPHotel) {
            
            [view setState:kAmenityDisplayEmpty];
            
        }
        
    }

    //Only set the aggregate indicator to grey if all are disconnected
    if (areAllAmenitiesDisconnected) {
        [self.amenitiesConnectionView setState:kAmenityDisplayEmpty];
    }

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/* TESTING */

- (void)addTestAmenityDoors {
    
    NSArray * allnames = @[@"one", @"two", @"three", @"four", @"five", @"six", @"seven", @"eight", @"nine", @"ten", @"eleven", @"twelve", @"thirteen", @"fourteen", @"fifteen", @"sixteen", @"seventeen", @"eighteen"];
    
    
    int numToShow = 12;
    
    NSMutableArray * namesToAdd = [NSMutableArray array];
    
    if (numToShow > 12)  {
        numToShow = 12;
    }
    
    for (int i = 0; i < numToShow; i++) {
        
        [namesToAdd addObject:allnames[i]];
        
    }
    
    NSArray * names = [NSArray arrayWithArray:namesToAdd];
    
    NSMutableArray * amenities = [NSMutableArray array];
    
    for (NSString * door in names) {
      
        //If the name is an even length, make it an access type
        BOOL isAccessType = [door length] % 2 == 0;
        
        NSString * subtype = isAccessType? @"access" : @"amenity";
        
        NSDictionary * newAmenity = @{@"name":door, @"open_time":@"10:00", @"close_time":@"12:00", @"subtype": subtype};
        YKSAmenityInfo * amenity = [YKSAmenityInfo newWithJSONDictionary:newAmenity];
        [amenities addObject:amenity ];
    }
    
    [self addDoorDisplays:[NSArray arrayWithArray:amenities]];
    return;
    
    /**
    
    names = @[@"Pool 2", @"Lounge", @"Pool 3", @"Restaurant"];
    //NSArray * names = @[@"Pool 2", @"Gym", @"Restaurant", @"Boo", @"Poo"];
    //NSArray * names = @[@"Pool 2"];
    
    amenities = [NSMutableArray array];
    
    NSUInteger index = 0;
    for (NSString * door in names) {
        
        NSDictionary * newAmenity = @{@"name":door, @"open_time":@"10:00", @"close_time":@"12:00", @"connection_status":@(index)};
        YKSAmenityInfo * amenity = [YKSAmenityInfo newWithJSONDictionary:newAmenity];
        
        [amenities addObject:amenity ];
        
        index++;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleAmenityDoorsUpdated:amenities];
    });
    
     */
    
}

- (void)handleAmenityDoorsUpdated:(NSArray *)newAmenities {
    
    //need to capture value outside block
    BOOL show = self.isShowingAmenityDoors;
    
    [self hideAmenityDoorsWithCompletionBlock:^{
        
        [self removeDoorDisplays];
        [self addDoorDisplays:newAmenities];
        [self setupAmenitiesCircle];
        
        if (show) {
            [self showAmenityDoors];
        }
        
    }];
    
}

- (void)removeDoorDisplays {
    
    for (NSDictionary * amenityEntry in self.amenityDoors.allValues) {
        
        IndicatorView * view = amenityEntry[@"view"];
        
        if (view) {
            [view removeFromSuperview];
        }
        
    }
    
    self.amenityDoors = nil;
    
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
