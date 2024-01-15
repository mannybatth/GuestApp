//
//  YKSStayDetailsVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/21/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSStayDetailsVC.h"
#import "YKSStayDetailsTC.h"
#import "YKSPhoneHelper.h"

@interface YKSStayDetailsVC ()

@end

@implementation YKSStayDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont * font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    NSDictionary * attributes = @{ NSFontAttributeName: font };
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

- (IBAction)closeButtonTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 9;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        
        case roomNumberSection:
            return @"ROOM NUMBER";
            break;
            
        case checkInSection:
            return @"CHECK-IN";
            break;
            
        case checkOutSection:
            return @"CHECK-OUT";
            break;
            
        case reservationNumberSection:
            return @"RESERVATION NUMBER";
            break;
            
        case amenitiesSection:
            return @"AMENITIES";
            break;
        
        case commonDoorsSection:
            return @"COMMON DOORS";
            break;
            
        case hotelNameSection:
            return @"HOTEL NAME";
            break;
            
        case hotelPhoneSection:
            return @"FRONT DESK";
            break;
            
        case hotelAddressSection:
            return @"HOTEL ADDRESS";
            break;
            
        default:
            break;
    }
    
    return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 26)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 3, tableView.frame.size.width, 19)];
    [label setFont:[UIFont fontWithName:@"HelveticaNeue" size:13.0]];
    [label setTextColor:[UIColor colorWithHexString:@"4A4A4A"]];
    [label setText:[self tableView:tableView titleForHeaderInSection:section]];
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithHexString:@"EDEDED"]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == hotelPhoneSection && [self.stay.hotelPhoneNumber isEqualToString:@""]) {
        return 0.0;
    }
    return 26.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [YKSStayDetailsTC heightOfCellAtSection:indexPath.section tableView:tableView withStay:self.stay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YKSStayDetailsTC *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSStayDetailsTC" forIndexPath:indexPath];
    
    cell.cellTextLabel.text = [YKSStayDetailsTC cellTextForRowAtSection:indexPath.section withStay:self.stay];
    cell.cellTextLabel.backgroundColor = [UIColor clearColor];
    
    if (indexPath.section == hotelPhoneSection) {
        
        cell.cellImageView.image = [UIImage imageNamed:@"call_hotel_gray_icon"];
        cell.textLabelLeftMarginConstraint.constant = 56;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.cellTextLabel.textColor = [UIColor colorWithHexString:@"5F9318"];
        
    } else if (indexPath.section == hotelAddressSection) {
        
        cell.cellImageView.image = [UIImage imageNamed:@"directions_gray_icon"];
        cell.textLabelLeftMarginConstraint.constant = 56;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.cellTextLabel.textColor = [UIColor colorWithHexString:@"5F9318"];
        
    } else {
        
        cell.cellImageView.image = nil;
        cell.textLabelLeftMarginConstraint.constant = 13;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.cellTextLabel.textColor = [UIColor colorWithHexString:@"4A4A4A"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == hotelPhoneSection) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
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
        [self presentViewController:alert animated:YES completion:nil];
        
    } else if (indexPath.section == hotelAddressSection) {
        
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
