//
//  YKSStayDetailsTC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/21/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSStayDetailsTC.h"
#import "YKSPhoneHelper.h"
#import "DateHelper.h"

@implementation YKSStayDetailsTC

+ (CGFloat)heightOfCellAtSection:(DetailSectionName)section tableView:(UITableView *)tableView withStay:(YKSStayInfo *)stay {
    
    if (section == hotelPhoneSection && [stay.hotelPhoneNumber isEqualToString:@""]) {
        return 0;
    }
    
    NSString *text = [YKSStayDetailsTC cellTextForRowAtSection:section withStay:stay];
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                         attributes:@{
                                                                                      NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:16.0]
                                                                                      }];
    CGFloat labelWidth;
    if (section == hotelPhoneSection || section == hotelAddressSection) {
        labelWidth = tableView.frame.size.width - 76;
    } else {
        labelWidth = tableView.frame.size.width - 33;
    }
    
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){labelWidth, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    
    return rect.size.height + 35;
    
}

+ (NSString *)cellTextForRowAtSection:(DetailSectionName)section withStay:(YKSStayInfo *)stay {
    
    switch (section) {
            
        case roomNumberSection:
            return stay.roomNumber ? stay.roomNumber :  @"Room not assigned";
            break;
            
        case checkInSection: {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateStyle:NSDateFormatterMediumStyle];
            NSString *arrivalDate = [dateFormat stringFromDate:stay.arrivalDate];
            NSString *checkInDateTime = [NSString stringWithFormat:@"%@ @ %@", arrivalDate, [DateHelper convertTo12HrTimeFrom24HrTime:stay.checkInTime]];
            return checkInDateTime;
            break;
        }
            
        case checkOutSection: {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateStyle:NSDateFormatterMediumStyle];
            NSString *departDate = [dateFormat stringFromDate:stay.departDate];
            NSString *checkOutDateTime = [NSString stringWithFormat:@"%@ @ %@", departDate, [DateHelper convertTo12HrTimeFrom24HrTime:stay.checkOutTime]];
            return checkOutDateTime;
            break;
        }
            
        case reservationNumberSection:
            return stay.reservationNumber;
            break;
            
        case amenitiesSection: {
            
            NSMutableString *amenitiesNames = [[NSMutableString alloc] initWithString:@""];
            BOOL isFirst = YES;
            for (YKSAmenityInfo *amenity in stay.amenities) {
                
                if (amenity.doorCategory == kYKSDoorCategoryAmenity) {
                    
                    if (!isFirst) {
                        [amenitiesNames appendString:@"\n"];
                    }
                    
                    [amenitiesNames appendString:amenity.name];
                    
                    if ([self isAlwaysOpen:amenity]) {
                        [amenitiesNames appendString:@" (Always Open)"];
                    } else {
                        [amenitiesNames appendFormat:@" (%@ - %@)", [DateHelper convertTo12HrTimeFrom24HrTime:amenity.openTime], [DateHelper convertTo12HrTimeFrom24HrTime:amenity.closeTime]];
                    }
                    
                    isFirst = NO;
                }
            }
            
            if ([amenitiesNames isEqualToString:@""]) {
                return @"None";
                break;
            }
            
            return amenitiesNames;
            break;
        }
            
        case commonDoorsSection: {
            
            NSMutableString *commonDoorNames = [[NSMutableString alloc] initWithString:@""];
            BOOL isFirst = YES;
            for (YKSAmenityInfo *amenity in stay.amenities) {
                
                if (amenity.doorCategory == kYKSDoorCategoryAccess) {
                    
                    if (!isFirst) {
                        [commonDoorNames appendString:@"\n"];
                    }
                    
                    [commonDoorNames appendString:amenity.name];
                    
                    if ([self isAlwaysOpen:amenity]) {
                        [commonDoorNames appendString:@" (Always Open)"];
                    } else {
                        [commonDoorNames appendFormat:@" (%@ - %@)", [DateHelper convertTo12HrTimeFrom24HrTime:amenity.openTime], [DateHelper convertTo12HrTimeFrom24HrTime:amenity.closeTime]];
                    }
                    
                    isFirst = NO;
                }
            }
            
            if ([commonDoorNames isEqualToString:@""]) {
                return @"None";
                break;
            }
            
            return commonDoorNames;
            break;
        }
            
        case hotelNameSection:
            return stay.hotelName;
            break;
            
        case hotelPhoneSection: {
            
            return [YKSPhoneHelper phoneWithSeperatorsForNumber:stay.hotelPhoneNumber];
            break;
        }
            
        case hotelAddressSection: {
            YKSAddressInfo *addressInfo = stay.hotelAddress;
            
            NSString *street = [NSString stringWithFormat:@"%@ %@ %@",
                                addressInfo.addressLine1,
                                addressInfo.addressLine2,
                                addressInfo.addressLine3];
            
            NSString *trimmedStreet = [street stringByTrimmingCharactersInSet:
                                       [NSCharacterSet whitespaceCharacterSet]];
            
            NSString *address = [NSString stringWithFormat:@"%@, %@, %@ %@",
                                 trimmedStreet,
                                 addressInfo.city,
                                 addressInfo.stateCode,
                                 addressInfo.postalCode];
            
            return address;
            break;
        }
            
        default:
            break;
    }
    
    return @"";
}

+ (BOOL)isAlwaysOpen:(YKSAmenityInfo *)amenity {
    
    if ([amenity.openTime isEqualToString:@"00:00"] && [amenity.closeTime isEqualToString:@"00:00"]) {
        return YES;
    } else if ([amenity.openTime isEqualToString:@"00:00"] && [amenity.closeTime isEqualToString:@"23:59"]) {
        return YES;
    } else if ([amenity.openTime isEqualToString:@""] && [amenity.closeTime isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}

@end
