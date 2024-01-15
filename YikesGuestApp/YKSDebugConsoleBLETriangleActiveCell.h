//
//  YKSDebugConsoleBLETriangleCell.h
//  yikes
//
//  Created by royksopp on 2015-02-03.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSDebugConsoleBLETriangleActiveCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *yManInfo;
@property (weak, nonatomic) IBOutlet UILabel *yLinkInfo;
@property (weak, nonatomic) IBOutlet UILabel *roomNumber;
@property (weak, nonatomic) IBOutlet UIImageView *connectedDot;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeInfo;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *RSSILabel;

@end
