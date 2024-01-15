//
//  YKSScanningYManTableViewCell.h
//  yikes
//
//  Created by royksopp on 2015-05-08.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSScanningYManTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *yManMacAddressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *yManConnectionDotImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *yManScanActivityIndicator;



@end
