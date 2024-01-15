//
//  YKSStayDetailsTC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/21/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DetailSectionName) {
    roomNumberSection,
    checkInSection,
    checkOutSection,
    reservationNumberSection,
    amenitiesSection,
    commonDoorsSection,
    hotelNameSection,
    hotelPhoneSection,
    hotelAddressSection
};

@interface YKSStayDetailsTC : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *cellTextLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textLabelLeftMarginConstraint;

+ (CGFloat)heightOfCellAtSection:(DetailSectionName)section tableView:(UITableView *)tableView withStay:(YKSStayInfo *)stay;
+ (NSString *)cellTextForRowAtSection:(DetailSectionName)section withStay:(YKSStayInfo *)stay;

@end
