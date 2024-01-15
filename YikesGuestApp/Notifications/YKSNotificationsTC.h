//
//  YKSNotificationsTC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 9/1/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YKSNotificationsTCDelegate;

@interface YKSNotificationsTC : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@property (nonatomic, weak) id<YKSNotificationsTCDelegate> delegate;

@property (strong, nonatomic) YKSStayShareInfo *stayShare;

- (void)setupViewWithStayShare:(YKSStayShareInfo *)stayShare;

@end

@protocol YKSNotificationsTCDelegate <NSObject>

- (void)acceptShareButtonTouched:(YKSNotificationsTC *)cell;
- (void)declineShareButtonTouched:(YKSNotificationsTC *)cell;

@end