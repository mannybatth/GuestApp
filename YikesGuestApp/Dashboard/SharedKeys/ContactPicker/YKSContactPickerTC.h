//
//  YKSContactPickerTC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/5/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YKSContactPickerTCDelegate;

@interface YKSContactPickerTC : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *contactAvatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactEmailLabel;
@property (weak, nonatomic) IBOutlet UIButton *removeContactButton;

@property (nonatomic, weak) id<YKSContactPickerTCDelegate> delegate;

@property (strong, nonatomic) YKSContactInfo *contactInfo;

- (void)setupViewWithContactInfo:(YKSContactInfo *)contactInfo;

@end

@protocol YKSContactPickerTCDelegate <NSObject>

- (void)removeContactButtonTouched:(YKSContactPickerTC *)cell;

@end
