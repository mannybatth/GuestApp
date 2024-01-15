//
//  AmenityView.h
//  YikesGuestApp
//
//  Created by Elliot Sinyor on 2015-07-08.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HexColors;

typedef NS_ENUM(NSUInteger, YKSIndicatorDisplayState) {
    
    kAmenityDisplayEmpty,
    kAmenityDisplaySolidGrey,
    kAmenityDisplayFlashingGrey,
    kAmenityDisplayFlashingGreen,
    kAmenityDisplaySolidGreen,
    kAmenityDisplayPulsingGrey,
    kAmenityDisplayPulsingGreen,
    
};

#define INDICATOR_WIDTH 62
#define INDICATOR_HEIGHT 62

@protocol IndicatorViewDelegate <NSObject>

- (void)indicatorViewButtonPushed:(UIButton *)button;

@end

@interface IndicatorView : UIView

@property (nonatomic) CGFloat outerCircleRadius;
@property (nonatomic) CGFloat innerCircleRadius;
@property (nonatomic) CGPoint finalPoint;
@property (nonatomic) CGFloat finalAlpha;

@property (weak, nonatomic) IBOutlet UIButton * button;
@property (weak, nonatomic) IBOutlet UIView * circleView;
@property (weak, nonatomic) IBOutlet UIView * innerCircleView;
@property (weak, nonatomic) IBOutlet UIView * tempStateCircleView;
@property (weak, nonatomic) IBOutlet UILabel * statusDescLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lockIconImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint * circleViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * circleViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * innerCircleViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * innerCircleViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tempStateCircleViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tempStateCircleViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * buttonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * buttonHeightConstraint;
@property (atomic, assign) YKSConnectionStatus lastConnectionStatus;

@property (nonatomic, weak) IBOutlet id<IndicatorViewDelegate> delegate;

//Used to cycle through all visual states. Arrange the enum order above to change cycle order
- (void)changeState;
- (void)setStatus:(YKSConnectionStatus)status;
- (void)setState:(YKSIndicatorDisplayState)state;
- (void)handleRoomDisconnectReason:(YKSDisconnectReasonCode)code;

@end
