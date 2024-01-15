//
//  YKSWalkthroughGetStartedTC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/12/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YKSWalkthroughGetStartedTCDelegate <NSObject>

- (void)actionButtonTouchedForIndex:(NSInteger)index;

@end

@interface YKSWalkthroughGetStartedTC : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *serviceTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *serviceDescLabel;
@property (weak, nonatomic) IBOutlet UIButton *serviceActionButton;

@property (nonatomic) NSInteger index;

@property (nonatomic, weak) id<YKSWalkthroughGetStartedTCDelegate> delegate;

- (void)setupCellForIndex:(NSInteger)index;
- (void)setActionButtonToChecked:(BOOL)checked;

+ (UITableViewCell *)cellForFooterNoteWithTableView:(UITableView *)tableview;

@end
