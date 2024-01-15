//
//  YKSContactPickerTC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/5/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSContactPickerTC.h"

@implementation YKSContactPickerTC

- (void)awakeFromNib {
    
    [super awakeFromNib];
}

- (void)setupViewWithContactInfo:(YKSContactInfo *)contactInfo {
    
    self.contactInfo = contactInfo;
    
    if (contactInfo.user.firstName || contactInfo.user.lastName) {
        self.contactNameLabel.text = [NSString stringWithFormat:@"%@ %@", contactInfo.user.firstName, contactInfo.user.lastName];
        self.contactEmailLabel.text = contactInfo.user.email;
    } else {
        self.contactNameLabel.text = contactInfo.user.email;
        self.contactEmailLabel.text = @"Select to share room with this email.";
    }
}

- (IBAction)removeContactButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeContactButtonTouched:)]) {
        [self.delegate removeContactButtonTouched:self];
    }
}

@end
