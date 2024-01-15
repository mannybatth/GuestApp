//
//  YKSNotificationsTC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 9/1/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSNotificationsTC.h"

@implementation YKSNotificationsTC

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.declineButton.layer.cornerRadius = 7;
    self.declineButton.clipsToBounds = YES;
    self.declineButton.layer.borderWidth = 1.0f;
    self.declineButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.acceptButton.layer.cornerRadius = 7;
    self.acceptButton.clipsToBounds = YES;
    
}

- (void)setupViewWithStayShare:(YKSStayShareInfo *)stayShare {
    
    self.stayShare = stayShare;
    
    if (stayShare.stay.roomNumber) {
        self.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@ wants to share room %@ with you at %@.",
                                      stayShare.primaryGuest.firstName,
                                      stayShare.primaryGuest.lastName,
                                      stayShare.stay.roomNumber,
                                      stayShare.stay.hotelName];
    } else {
        self.descriptionLabel.text = [NSString stringWithFormat:@"%@ %@ wants to share a room with you at %@.",
                                      stayShare.primaryGuest.firstName,
                                      stayShare.primaryGuest.lastName,
                                      stayShare.stay.hotelName];
    }
}

- (IBAction)acceptShareButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(acceptShareButtonTouched:)]) {
        [self.delegate acceptShareButtonTouched:self];
    }
}

- (IBAction)declineShareButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(declineShareButtonTouched:)]) {
        [self.delegate declineShareButtonTouched:self];
    }
}

@end
