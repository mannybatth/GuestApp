//
//  YKSDashboardCardOptionsVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 8/31/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSDashboardCardOptionsVC.h"
#import "YKSStayDetailsNC.h"
#import "YKSStayDetailsVC.h"
#import "YKSSharedKeysVC.h"
#import "YKSPhoneHelper.h"
#import "M13BadgeView.h"
#import "YKSDashboardCardVC.h"

@interface YKSDashboardCardOptionsVC ()

@property (nonatomic, strong) M13BadgeView *sharedKeysCountBadge;

@end

@implementation YKSDashboardCardOptionsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    // Adjust option button insets to make image centered
    [self centerTextAndImageForButton:self.callHotelButton];
    [self centerTextAndImageForButton:self.directionButton];
    [self centerTextAndImageForButton:self.sharedKeysButton];
    [self centerTextAndImageForButton:self.weatherButton];
    [self centerTextAndImageForButton:self.stayDetailsButton];
    
    if (self.sharedKeysButtonSelected) {
        
        self.callHotelButton.enabled = NO;
        self.directionButton.enabled = NO;
        self.weatherButton.enabled = NO;
        self.stayDetailsButton.enabled = NO;
        
        [self.sharedKeysButton setImage:[UIImage imageNamed:@"shared_keys_icon_selected"] forState:UIControlStateNormal];
        
    }
    
    self.sharedKeysCountBadge = [[M13BadgeView alloc] initWithFrame:CGRectMake(20, 20, 18, 18)];
    [self.sharedKeysCountBadge setFont:[UIFont fontWithName:@"HelveticaNeue" size:10.0]];
    [self.sharedKeysCountBadge setTextColor:[UIColor colorWithHexString:@"FFFFFF"]];
    [self.sharedKeysCountBadge setBadgeBackgroundColor:[UIColor colorWithHexString:@"A1A1A1"]];
    [self.sharedKeysCountBadge setBorderColor:[UIColor colorWithHexString:@"FFFFFF"]];
    [self.sharedKeysCountBadge setBorderWidth:1.0f];
    [self.sharedKeysCountBadge setShadowBadge:NO];
    [self.sharedKeysCountBadge setHidesWhenZero:YES];
    [self.sharedKeysCountBadge setAlignmentShift:CGSizeMake(-22.0f, 12.0f)];
    [self.sharedKeysButton addSubview:self.sharedKeysCountBadge];
    
    [self updateSharedKeysCountBadge];
}

- (void)updateSharedKeysCountBadge {
    
    YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
    
    if (![self.stay.userId isEqualToNumber:user.userId]) {
        self.sharedKeysButton.enabled = NO;
    }
    
    NSInteger numOfSharedKeys = 0;
    for (YKSStayShareInfo *stayShare in user.stayShares) {
        if ([stayShare.primaryGuest.userId isEqualToNumber:user.userId] &&
            [stayShare.stay.stayId isEqualToNumber:self.stay.stayId] &&
            ![stayShare.status isEqualToString:@"cancelled"] &&
            ![stayShare.status isEqualToString:@"declined"]) {
            
            numOfSharedKeys++;
        }
    }
    
    // Only show invites for this stay and have not yet been accepted/declined
    for (YKSUserInviteInfo *userInvite in user.userInvites) {
        if ([userInvite.relatedStayId isEqualToNumber:self.stay.stayId] &&
            userInvite.isAccepted == NO &&
            userInvite.isDeclined == NO) {
            
            numOfSharedKeys++;
        }
    }
    
    CGRect frame = CGRectZero;
    
    if ([self.sharedKeysCountBadge.text isEqualToString:[NSString stringWithFormat:@"%li", (long)numOfSharedKeys]]) {
        frame = self.sharedKeysCountBadge.frame;
    }
    
    self.sharedKeysCountBadge.text = [NSString stringWithFormat:@"%li", (long)numOfSharedKeys];
    
    if (!CGRectEqualToRect(frame, CGRectZero)) {
        self.sharedKeysCountBadge.frame = frame;
    }
}

- (void)centerTextAndImageForButton:(UIButton*)button {
    
    // the space between the image and text
    CGFloat spacing = 4.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake( 0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake( - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    
}

- (IBAction)callHotelButtonTouched:(id)sender {
    
    PKAlertViewController *alert;
    
    if ([self.stay.hotelPhoneNumber isEqualToString:@""]) {
        
        alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = self.stay.hotelName;
            configuration.message = @"No phone number found for this hotel.";
            [configuration addAction:[PKAlertAction okAction]];
            
        }];
        
    } else {
        
        alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = self.stay.hotelName;
            configuration.message = [NSString stringWithFormat:@"Call %@", [YKSPhoneHelper phoneWithSeperatorsForNumber:self.stay.hotelPhoneNumber]];
            
            [configuration addAction:[PKAlertAction cancelAction]];
            [configuration addAction:[PKAlertAction actionWithTitle:@"Call" handler:^(PKAlertAction *action, BOOL closed) {
                
                if (closed) {
                    NSString *phoneNumber = [@"tel://" stringByAppendingString:self.stay.hotelPhoneNumber];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
                }
                
            }]];
            
        }];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)directionsButtonTouched:(id)sender {
    
    NSString *fullAddress = @"";
    
    if ([self.stay.hotelAddress.addressLine1 length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.addressLine1];
    }
    if ([self.stay.hotelAddress.addressLine2 length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:@" "];
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.addressLine2];
    }
    if ([self.stay.hotelAddress.addressLine3 length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:@" "];
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.addressLine3];
    }
    if ([self.stay.hotelAddress.city length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:@" "];
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.city];
    }
    if ([self.stay.hotelAddress.country length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:@" "];
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.country];
    }
    if ([self.stay.hotelAddress.postalCode length] > 0) {
        fullAddress = [fullAddress stringByAppendingString:@" "];
        fullAddress = [fullAddress stringByAppendingString:self.stay.hotelAddress.postalCode];
    }
    
    NSString *encodedString = [fullAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if ([UIAlertController class]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Directions to hotel" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
            [alertController addAction:[UIAlertAction actionWithTitle:@"Google Maps" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?q=%@", encodedString]];
                [[UIApplication sharedApplication] openURL:url];
                
            }]];
        }
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Apple Maps" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?q=%@", encodedString]];
            [[UIApplication sharedApplication] openURL:url];
            
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?q=%@", encodedString]];
            [[UIApplication sharedApplication] openURL:url];
            
        } else {
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?q=%@", encodedString]];
            [[UIApplication sharedApplication] openURL:url];
            
        }
        
    }
    
}

- (IBAction)sharedKeysButtonTouched:(id)sender {
    
    if (self.sharedKeysButtonSelected) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if (!self.stay.maxStaySharesAllowed ||
        self.stay.maxStaySharesAllowed.integerValue == 0) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"Feature not supported";
            configuration.message = @"This hotel does not support shared keys yet.";
            
            [configuration addAction:[PKAlertAction okAction]];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"YKSSharedKeysNC"];
    
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    nc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    YKSSharedKeysVC *sharedKeysVC = (YKSSharedKeysVC *)nc.topViewController;
    sharedKeysVC.stay = self.stay;
    sharedKeysVC.dashCardVC = self.dashCardVC;
    [self presentViewController:nc animated:YES completion:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"StayDetailsSegue"]) {
        
        UINavigationController *nc = segue.destinationViewController;
        if ([nc.topViewController isKindOfClass:[YKSStayDetailsVC class]]) {
            YKSStayDetailsVC *stayDetailsVC = (YKSStayDetailsVC *)nc.topViewController;
            stayDetailsVC.stay = self.stay;
        }
        
    }
}

@end
