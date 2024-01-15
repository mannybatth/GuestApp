//
//  YKSImportContactsVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/6/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSBaseVC.h"
#import "YKSContactPickerVC.h"

@interface YKSImportContactsVC : YKSBaseVC

@property (nonatomic, weak) id<YKSContactPickerVCDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *importContactsButton;
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;

@end
