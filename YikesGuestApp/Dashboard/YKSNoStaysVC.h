//
//  YKSNoStaysVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/11/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@import HexColors;

@interface YKSNoStaysVC : YKSBaseVC

@property (weak, nonatomic) IBOutlet UIView * playerView;
@property (weak, nonatomic) IBOutlet UILabel * noStaysLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView * spinner;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer * tapGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeUpGR;


- (void)yikesEngineUserInfoDidUpdate:(YKSUserInfo *)yikesUser;

@end
