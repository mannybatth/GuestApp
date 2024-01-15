//
//  AmenityView.m
//  YikesGuestApp
//
//  Created by Elliot Sinyor on 2015-07-08.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "IndicatorView.h"
#import "MultiplePulsingHaloLayer.h"
#import "PulsingHaloLayer.h"

NSString * const kButtonBackgroundImageName = @"amenities_circle";

@interface IndicatorView ()

@property (assign) YKSIndicatorDisplayState displayState;
@property (strong) PulsingHaloLayer * pulseView;

@property (strong, nonatomic) UIColor * solidGreenColor;
@property (strong, nonatomic) UIColor * lightGreenColor;
@property (strong, nonatomic) UIColor * solidGrey;
@property (strong, nonatomic) UIColor * textLightGrey;
@property (strong, nonatomic) UIColor * warningYellowColor;
@property (strong, nonatomic) UIColor * errorRedColor;
@property (strong, nonatomic) NSTimer* pulsingGreyTimer;

@end


@implementation IndicatorView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self addSubview:[[[NSBundle mainBundle] loadNibNamed:@"IndicatorView"
                                                        owner:self
                                                      options:nil] objectAtIndex:0]];
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:[[[NSBundle mainBundle] loadNibNamed:@"IndicatorView"
                                                        owner:self
                                                      options:nil] objectAtIndex:0]];
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:[[[NSBundle mainBundle] loadNibNamed:@"IndicatorView"
                                                        owner:self
                                                      options:nil] objectAtIndex:0]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)dealloc {
    self.delegate = nil;
    if (self.pulsingGreyTimer) {
        [self.pulsingGreyTimer invalidate];
        self.pulsingGreyTimer = nil;
    }
}

- (void)setup {
    
    self.backgroundColor = [UIColor clearColor];
    
    if (/* DISABLES CODE */ (NO)) {
        self.lockIconImageView.hidden = NO;
    }
    else {
        self.lockIconImageView.hidden = YES;
    }
    
    /*
     self.flashGreen = [UIColor colorWithRed:170.0/255.0 green:254.0/255.0 blue:66.0/255.0 alpha:0.8];
     self.flashGreen = [UIColor colorWithHexString:@"8DC63F"];

     self.solidGreenColor = [UIColor colorWithRed:141.0/255.0 green:198.0/255.0 blue:63.0/255.0 alpha:1.0];
     self.lightGreenColor = [UIColor colorWithRed:170.0/255.0 green:254.0/255.0 blue:66.0/255.0 alpha:0.8];
     */
    
    self.solidGreenColor = [UIColor colorWithHexString:@"8DC63F"];
    self.lightGreenColor = [UIColor colorWithHexString:@"AAFE42"];
    self.solidGrey = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:0.3];
    self.textLightGrey = [UIColor colorWithHexString:@"E3E3E3"];
    self.warningYellowColor = [UIColor colorWithHexString:@"F8E71C" alpha:0.2];
    self.errorRedColor = [UIColor colorWithHexString:@"EC1616" alpha:0.2];
    
    self.outerCircleRadius = 62;
    self.innerCircleRadius = 50;
    
    self.displayState = 0;
    
    self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self initPulseView];
    [self updateFrames];
    
}

- (IBAction)amenityViewTapped:(UIButton *)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(indicatorViewButtonPushed:)]) {
        [self.delegate indicatorViewButtonPushed:sender];
    }
    
}

- (void)initPulseView {
    
    if (!self.pulseView) {
        self.pulseView = [PulsingHaloLayer layer];
        self.pulseView.animationDuration = 1.0;
        self.pulseView.pulseInterval = 0.1;
        self.pulseView.keyTimeForHalfOpacity = 0.7;
        self.pulseView.backgroundColor = self.solidGreenColor.CGColor;
        [self.layer insertSublayer:self.pulseView below:self.button.layer];
        
        self.pulseView.hidden = YES;
    }
    
}

- (void)updateFrames {
    
    self.pulseView.position = CGPointMake(self.outerCircleRadius / 2.0, self.outerCircleRadius / 2.0);
    self.pulseView.radius = 1.2*(self.outerCircleRadius / 2.0);
    
    self.buttonHeightConstraint.constant = self.outerCircleRadius;
    self.buttonWidthConstraint.constant = self.outerCircleRadius;
    
    self.circleViewHeightConstraint.constant = self.outerCircleRadius;
    self.circleViewWidthConstraint.constant = self.outerCircleRadius;
    
    self.innerCircleViewHeightConstraint.constant = self.innerCircleRadius;
    self.innerCircleViewWidthConstraint.constant = self.innerCircleRadius;
    
    self.tempStateCircleViewHeightConstraint.constant = self.outerCircleRadius-3;
    self.tempStateCircleViewWidthConstraint.constant = self.outerCircleRadius-3;
    
    self.circleView.layer.cornerRadius = self.outerCircleRadius / 2.0;
    self.innerCircleView.layer.cornerRadius = self.innerCircleRadius / 2.0;
    self.tempStateCircleView.layer.cornerRadius = self.innerCircleRadius / 2.0;
    
}

- (void)changeState {
    
    [self setState:self.displayState];
    
    self.displayState += 1;
    if (self.displayState > 6) {
        self.displayState = 0;
    }
    
}

- (void)setStatus:(YKSConnectionStatus)status {
    
    self.lastConnectionStatus = status;
    
    switch (status) {
            
            
        case kYKSConnectionStatusDisconnectedFromDoor:
            [self setState:kAmenityDisplaySolidGrey];
            break;
            
        case kYKSConnectionStatusScanningForDoor:
            [self setState:kAmenityDisplayPulsingGrey];
            break;
            
        case kYKSConnectionStatusConnectingToDoor:
            [self setState:kAmenityDisplayPulsingGreen];
            break;
            
        case kYKSConnectionStatusConnectedToDoor:
            [self setState:kAmenityDisplaySolidGreen];
            break;
            
//        case kYKSStatusOutOfBeaconRegion:
//            [self setState:kAmenityDisplayEmpty];
//            break;
            
        default:
            [self setState:kAmenityDisplayEmpty];
            break;
    }
    
}

- (void)setState:(YKSIndicatorDisplayState)state {
    
    self.tempStateCircleView.hidden = YES;
    self.statusDescLabel.hidden = YES;
    
    switch (state) {
        case kAmenityDisplaySolidGrey:
            [self stopPulsingGreyTimer];
            [self stopPulsingView];
            [self stopFlash];
            
            [self showButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = NO;
            self.circleView.alpha = 0.8;
            self.circleView.backgroundColor = self.solidGrey;
            self.innerCircleView.hidden = YES;
            
            break;
            
        case kAmenityDisplaySolidGreen:
            [self stopPulsingGreyTimer];
            [self stopPulsingView];
            [self stopFlash];
            
            [self hideButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = NO;
            self.circleView.alpha = 0.4;
            self.circleView.backgroundColor = self.lightGreenColor;
            self.innerCircleView.hidden = NO;
            self.innerCircleView.backgroundColor = self.solidGreenColor;
            
            break;
            
        case kAmenityDisplayFlashingGreen:
            [self stopPulsingGreyTimer];
            [self stopPulsingView];
            [self flashCircle];
            
            [self hideButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = NO;
            self.circleView.backgroundColor = self.solidGreenColor;
            self.innerCircleView.hidden = YES;
            
            break;
            
        case kAmenityDisplayFlashingGrey:
            [self stopPulsingGreyTimer];
            [self stopPulsingView];
            [self flashCircle];
            
            [self hideButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = NO;
            self.circleView.backgroundColor = self.solidGrey;
            self.innerCircleView.hidden = YES;
            
            break;
            
        case kAmenityDisplayPulsingGreen:
            [self stopPulsingGreyTimer];
            [self showPulsingViewWithColor:self.solidGreenColor];
            [self stopFlash];
            
            [self hideButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = YES;
            self.innerCircleView.hidden = YES;
            
            break;
            
        case kAmenityDisplayPulsingGrey:
            
            [self showPulsingViewWithColor:self.solidGrey];
            [self stopFlash];
            [self startPulsingGreyTimer];
            
            [self hideButtonCircleImage];
            self.button.titleLabel.textColor = [UIColor whiteColor];
            
            self.circleView.hidden = YES;
            self.innerCircleView.hidden = YES;
            
            break;
            
        case kAmenityDisplayEmpty:
            [self stopPulsingGreyTimer];
            [self stopPulsingView];
            [self stopFlash];
            
            [self showButtonCircleImage];
            self.button.titleLabel.textColor = self.textLightGrey;
            
            self.circleView.hidden = YES;
            self.innerCircleView.hidden = YES;
            
            break;
            
        default:
            break;
            
            
    }
}


- (void)startPulsingGreyTimer {
    self.pulseView.hidden = NO;
    
    if (self.pulsingGreyTimer == nil) {
        self.pulsingGreyTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(stopPulsingGreyTimer) userInfo:nil repeats:NO];
    }
    else {
        [self.pulsingGreyTimer invalidate];
        self.pulsingGreyTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(stopPulsingGreyTimer) userInfo:nil repeats:NO];
    }
}

- (void)stopPulsingGreyTimer {
    self.pulseView.hidden = YES;
    
    if (self.pulsingGreyTimer) {
        [self.pulsingGreyTimer invalidate], self.pulsingGreyTimer = nil;
    }
    
    [self stopPulsingView];
    [self stopFlash];
    [self showButtonCircleImage];
    
    if ([[YikesEngine sharedEngine] isInsideHotel]) {
        
        self.button.titleLabel.textColor = [UIColor whiteColor];
        
        self.circleView.hidden = NO;
        self.circleView.alpha = 0.8;
        self.circleView.backgroundColor = self.solidGrey;
    }
    else {
        self.button.titleLabel.textColor = self.textLightGrey;
        self.circleView.hidden = YES;
    }
    self.innerCircleView.hidden = YES;
    
}


- (void)showButtonCircleImage {
    [self.button setBackgroundImage:[UIImage imageNamed:kButtonBackgroundImageName] forState:UIControlStateNormal];
}

- (void)hideButtonCircleImage {
    [self.button setBackgroundImage:nil forState:UIControlStateNormal];
}

- (void)showPulsingViewWithColor:(UIColor *)color {
    
    self.pulseView.hidden = NO;
    [self.pulseView setBackgroundColor:color.CGColor];
    
}

- (void)stopPulsingView {

    self.pulseView.hidden = YES;
}

- (void)setOuterCircleRadius:(CGFloat)outerCircleRadius {
    
    _outerCircleRadius = outerCircleRadius;
    
    [self updateFrames];
}

- (void)setInnerCircleRadius:(CGFloat)innerCircleRadius {
    
    _innerCircleRadius = innerCircleRadius;
    
    [self updateFrames];
}

- (void)flashCircle {

    [self.circleView.layer removeAllAnimations];
    
    self.circleView.alpha = 0.0;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        
        self.circleView.alpha = 0.6;
    
    } completion:^(BOOL finished){
    }];
    
}

- (void)stopFlash {
   
    [self.circleView.layer removeAllAnimations];
    
}

- (void)handleRoomDisconnectReason:(YKSDisconnectReasonCode)code {
    
    if (code == kYKSDisconnectReasonCodeProximity) {
        self.tempStateCircleView.backgroundColor = self.warningYellowColor;
        self.statusDescLabel.text = @"get closer";
    }
    else if (code == kYKSDisconnectReasonCodeExpired || code == kYKSDisconnectReasonCodeSuperseded) {
        self.tempStateCircleView.backgroundColor = self.errorRedColor;
        self.statusDescLabel.text = @"key expired";
    }
    else {
        return;
    }
    
    self.circleView.hidden = YES;
    self.innerCircleView.hidden = YES;
    self.tempStateCircleView.hidden = NO;
    self.statusDescLabel.hidden = NO;
    
    self.tempStateCircleView.alpha = 1.0f;
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionAutoreverse
                     animations:^ {
                         [UIView setAnimationRepeatCount:5.0f];
                         self.tempStateCircleView.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         self.tempStateCircleView.alpha = 1.0f;
                     }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.tempStateCircleView.hidden = YES;
        self.statusDescLabel.hidden = YES;
        self.statusDescLabel.text = @"";
        [self setStatus:self.lastConnectionStatus];
    });
}


@end
