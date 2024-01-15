//
//  YKSDebugConsoleBLETriangleFinishedCellTableViewCell.h
//  yikes
//
//  Created by royksopp on 2015-05-12.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSDebugConsoleBLETriangleFinishedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *yManInfo;
@property (weak, nonatomic) IBOutlet UILabel *yLinkInfo;
@property (weak, nonatomic) IBOutlet UILabel *roomNumber;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeInfo;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;


@end
