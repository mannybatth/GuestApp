//
//  YKSLicenseAgreementVC.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/27/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import <UIKit/UIKit.h>

@import YikesGenericEngine;

@interface YKSLicenseAgreementVC : UIViewController <UIScrollViewDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView * webView;

@end
