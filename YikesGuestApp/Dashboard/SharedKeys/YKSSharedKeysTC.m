//
//  YKSSharedKeysTC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSSharedKeysTC.h"

@implementation YKSSharedKeysTC

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.initialsView.layer.cornerRadius = 25;
    self.initialsView.clipsToBounds = YES;
    self.initialsView.layer.borderWidth = 1.0f;
    self.initialsView.layer.borderColor = [UIColor whiteColor].CGColor;
    
}

- (void)setupViewWithStayShare:(YKSStayShareInfo *)stayShare {
    
    self.stayShare = stayShare;
    self.userInvite = nil;
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", stayShare.secondaryGuest.firstName, stayShare.secondaryGuest.lastName];
    self.emailLabel.text = stayShare.secondaryGuest.email;
    self.initialsLabel.text = [NSString stringWithFormat:@"%@%@", [stayShare.secondaryGuest.firstName substringToIndex:1], [stayShare.secondaryGuest.lastName substringToIndex:1]];;
    self.statusLabel.text = stayShare.status;
    
    self.statusImageView.hidden = NO;
    self.deleteShareButton.hidden = NO;
    self.initialsView.hidden = NO;
    self.avatarImageView.hidden = YES;
    
    if ([stayShare.status isEqualToString:@"accepted"]) {
        [self.statusImageView setImage:[UIImage imageNamed:@"check"]];
        [self.statusLabel setTextColor:[UIColor colorWithHexString:@"ABFF42"]];
    } else {
        [self.statusImageView setImage:[UIImage imageNamed:@"pending"]];
        [self.statusLabel setTextColor:[UIColor whiteColor]];
    }
}

- (void)setupViewWithUserInvite:(YKSUserInviteInfo *)userInvite {
    
    self.stayShare = nil;
    self.userInvite = userInvite;
    
    self.nameLabel.text = userInvite.email;
    self.emailLabel.text = @"Email invitation sent.";
    self.initialsLabel.text = @"";
    self.statusLabel.text = @"";
    
    self.statusImageView.hidden = YES;
    self.deleteShareButton.hidden = NO;
    self.initialsView.hidden = YES;
    self.avatarImageView.hidden = NO;
    
}

- (IBAction)resendShareButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(resendShareButtonTouched:)]) {
        [self.delegate resendShareButtonTouched:self];
    }
}

- (IBAction)deleteShareButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteShareButtonTouched:)]) {
        [self.delegate deleteShareButtonTouched:self];
    }
}


@end
