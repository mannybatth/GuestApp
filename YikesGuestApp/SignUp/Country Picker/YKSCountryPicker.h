//
//  YKSCountryPicker.h
//  YikesGuestApp
//
//  Created by Manny Singh on 7/23/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YKSCountry.h"

@protocol YKSCountryPickerDelegate <NSObject>

- (void)countryController:(id)sender didSelectCountry:(YKSCountry *)chosenCountry;

@end

@interface YKSCountryPicker : UIViewController

@property (nonatomic, weak) id<YKSCountryPickerDelegate> delegate;

@property (strong, nonatomic) YKSCountry *selectedCountry;

@end
