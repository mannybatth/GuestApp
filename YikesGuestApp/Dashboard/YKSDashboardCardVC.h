//
//  YKSDashboardCardVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/16/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YKSAmenityViewController.h"

@protocol YKSDashboardCardVCDelegate <NSObject>

- (void)backArrowButtonTouchedFromCardWithIndex:(NSUInteger)cardIndex;
- (void)nextArrowButtonTouchedFromCardWithIndex:(NSUInteger)cardIndex;

@end

@interface YKSDashboardCardVC : UIViewController

@property (weak, nonatomic) IBOutlet UILabel * hotelTitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView * hotelBgImageView;

@property (weak, nonatomic) IBOutlet UILabel * numberOfNightsLabel;
@property (weak, nonatomic) IBOutlet UILabel * nightsLabel;
@property (weak, nonatomic) IBOutlet UILabel * checkInDateLabel;
@property (weak, nonatomic) IBOutlet UILabel * checkOutDateLabel;
@property (weak, nonatomic) IBOutlet UILabel * roomNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel * roomNumberCaptionLabel;
@property (weak, nonatomic) IBOutlet UILabel * roomNotAssignedLabel;
@property (weak, nonatomic) IBOutlet IndicatorView * roomConnectionView;

@property (weak, nonatomic) IBOutlet UIButton * backArrowButton;
@property (weak, nonatomic) IBOutlet UIButton * nextArrowButton;

@property (weak, nonatomic) IBOutlet UIView * optionsContainerView;
@property (weak, nonatomic) IBOutlet UIView * extraShadeView;

@property (weak, nonatomic) IBOutlet UILabel * sharedKeysCaptionLabel;

@property (weak, nonatomic) IBOutlet UIPageControl * pageControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * amenitiesTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * amenitiesBottomConstraint;

@property (weak, nonatomic) IBOutlet UIView * progressBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * progressBarWidthConstraint;

@property (weak, nonatomic) IBOutlet UIView *stayStatusContainer;
@property (weak, nonatomic) IBOutlet UIButton *stayStatusButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stayStatusContainerTopConstraint;

@property (weak, nonatomic) YKSAmenityViewController * amenityVC;

@property (nonatomic, weak) id<YKSDashboardCardVCDelegate> delegate;

@property (strong, nonatomic) YKSStayInfo * stay;
@property (nonatomic) NSUInteger cardIndex;
@property (nonatomic) NSUInteger totalNumOfCards;

- (void)setupView;
- (void)setExtraShadeAlpha:(CGFloat)alpha inTime:(NSTimeInterval)fadeTime;

- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber;
- (void)handleRoomEvent:(YKSConnectionStatus)newStatus forRoomNumber:(NSString *)roomNumber disconnectReasonCode:(YKSDisconnectReasonCode)code;
- (void)handleEvent:(YKSLocationState)state;
- (void)handleRequiredServicesMissing:(NSSet *)missingServices;

- (void)amenitiesViewHasBeenToggled:(BOOL)isHidden;

- (void)updateStayStatusDisplay;
- (void)updateCheckinAndCheckoutLabels;
- (void)stopStayStatusUpdateTimer;
- (void)stopCheckinCheckoutLabelTimer;
- (void)numberOfSharedKeysDidChange;

@end
