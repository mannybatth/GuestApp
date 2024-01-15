//
//  YKSYManTableConnectionsViewController.h
//  yikes
//
//  Created by royksopp on 2015-05-08.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YKSYManTableConnectionsViewController : UIViewController

//TODO: add delegate for new yMan data available in DebugManager
//@property (nonatomic, strong) id ;
@property (weak, nonatomic) IBOutlet UITableView *scanningYManTableView;

@end
