//
//  YKSSharedKeysTC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import HexColors;

@protocol YKSSharedKeysTCDelegate;

@interface YKSSharedKeysTC : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *initialsView;
@property (weak, nonatomic) IBOutlet UILabel *initialsLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *resendShareButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteShareButton;

@property (nonatomic, weak) id<YKSSharedKeysTCDelegate> delegate;

@property (strong, nonatomic) YKSStayShareInfo *stayShare;
@property (strong, nonatomic) YKSUserInviteInfo *userInvite;

- (void)setupViewWithStayShare:(YKSStayShareInfo *)stayShare;
- (void)setupViewWithUserInvite:(YKSUserInviteInfo *)userInvite;

@end

@protocol YKSSharedKeysTCDelegate <NSObject>

- (void)resendShareButtonTouched:(YKSSharedKeysTC *)cell;
- (void)deleteShareButtonTouched:(YKSSharedKeysTC *)cell;

@end
