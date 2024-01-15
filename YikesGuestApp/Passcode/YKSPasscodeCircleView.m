//
//  YKSPasscodeCircleView.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/17/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSPasscodeCircleView.h"

@implementation YKSPasscodeCircleView

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.layer.cornerRadius = 12.5f / 2.0f;
    self.layer.borderColor = [self.tintColor CGColor];
    self.layer.borderWidth = 1.0f;
    self.filled = NO;
    
}

- (void)setFilled:(BOOL)filled {
    self.backgroundColor = (filled) ? self.tintColor : [UIColor clearColor];
}

@end
