//
//  YKSContactPickerVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/2/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSBaseVC.h"

@import HexColors;

@protocol YKSContactPickerVCDelegate <NSObject>

- (void)didSelectContactWithInfo:(YKSContactInfo *)contactInfo;

@end

@interface YKSContactPickerVC : YKSBaseVC

@property (nonatomic, weak) id<YKSContactPickerVCDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *searchBarContainerView;
@property (weak, nonatomic) IBOutlet UIView *tabsContainerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tabsContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * selectedBarViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * selectedBarViewTrailingConstraint;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *allContactsTabButton;
@property (weak, nonatomic) IBOutlet UIButton *recentContactsTabButton;

@property (nonatomic) BOOL contactsAllowed;

@end
