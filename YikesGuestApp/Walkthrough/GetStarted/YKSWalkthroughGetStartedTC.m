//
//  YKSWalkthroughGetStartedTC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/12/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSWalkthroughGetStartedTC.h"
@import HexColors;

@implementation YKSWalkthroughGetStartedTC

- (void)setupCellForIndex:(NSInteger)index {
    
    self.index = index;
    
    if (index == 0) {
        
        self.serviceTitleLabel.text = @"Bluetooth turned on";
        [self.iconImageView setImage:[UIImage imageNamed:@"icon_bluetooth"]];
        
    } else if (index == 1) {
        
        self.serviceTitleLabel.text = @"Location Services enabled";
        [self.iconImageView setImage:[UIImage imageNamed:@"icon_location"]];
        
    } else if (index == 2) {
        
        self.serviceTitleLabel.text = @"Push Notifications enabled";
        [self.iconImageView setImage:[UIImage imageNamed:@"icon_push"]];
        
    }
    
    self.serviceDescLabel.text = [YKSWalkthroughGetStartedTC cellDescForIndex:index];
    
}

+ (NSString *)cellDescForIndex:(NSInteger)index {
    
    if (index == 0) {
        
        return @"for secure communications between your phone and the doors";
        
    } else if (index == 1) {
        
        return @"allows the app to know when to start doing its thing";
        
    } else if (index == 2) {
     
        return @"to keep you up-to-date about your stay";
        
    }
    
    return nil;
}

- (void)setActionButtonToChecked:(BOOL)checked {
    
    if (checked) {
        
        [self.serviceActionButton setTitle:@"" forState:UIControlStateNormal];
        [self.serviceActionButton setImage:[UIImage imageNamed:@"enabled"] forState:UIControlStateNormal];
        [self.serviceActionButton setEnabled:NO];
        
    } else {
        
        [self.serviceActionButton setTitle:@"enable" forState:UIControlStateNormal];
        [self.serviceActionButton setImage:[UIImage imageNamed:@"outline-enable"] forState:UIControlStateNormal];
        [self.serviceActionButton setEnabled:YES];
        
    }
    
}

+ (UITableViewCell *)cellForFooterNoteWithTableView:(UITableView *)tableview {
    
    static NSString *simpleTableIdentifier = @"YKSDefaultGetStartedTC";
    UITableViewCell *cell = [tableview dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        cell.textLabel.numberOfLines = 0;
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = @"Note: If airplane mode is enabled, the app needs to be on screen to unlock doors.";
    cell.textLabel.textColor = [UIColor colorWithHexString:@"2B2B2B"];
    
    return cell;
}

- (IBAction)enableButtonTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(actionButtonTouchedForIndex:)]) {
        [self.delegate actionButtonTouchedForIndex:self.index];
    }
}

@end
