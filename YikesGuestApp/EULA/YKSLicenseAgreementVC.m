//
//  YKSLicenseAgreementVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/27/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSLicenseAgreementVC.h"

@interface YKSLicenseAgreementVC ()

@property (nonatomic, assign) BOOL didScrollToTheEnd;

@end

@implementation YKSLicenseAgreementVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.didScrollToTheEnd = NO;
    self.navigationItem.hidesBackButton = YES;
    self.webView.scrollView.delegate = self;
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"EULA" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)willMoveToParentViewController:(UIViewController *)parent{
    if (parent == NULL) {
        CLS_LOG(@"EULA VC: back button pressed.");
        
        [[YikesEngine sharedEngine] stopEngineWithSuccess:nil];
    }
}

- (IBAction)dismissButtonTouched:(id)sender {
    
    // stop engine & quit app
    
    CLS_LOG(@"EULA dismissed.");
    
    [[YikesEngine sharedEngine] stopEngineWithSuccess:nil];
    
    PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
        
        configuration.title = @"y!kes";
        configuration.message = @"In order to continue using y!kes, you will need to accept our End User License Agreement.";
        PKAlertAction *okHandler = [PKAlertAction okActionWithHandler:^(PKAlertAction *action, BOOL closed) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [configuration addAction:okHandler];
        
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)acceptButtonTouched:(id)sender {
    
    if (! self.didScrollToTheEnd) {
        
        PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
            
            configuration.title = @"y!kes";
            configuration.message = @"Please read to the bottom before accepting our End User License Agreement.";
            PKAlertAction *okHandler = [PKAlertAction okActionWithHandler:^(PKAlertAction *action, BOOL closed) {
                //
            }];
            [configuration addAction:okHandler];
            
        }];
        [self presentViewController:alert animated:YES completion:nil];
    
    }
    else {
        YKSUserInfo *user = [[YikesEngine sharedEngine] userInfo];
        
        CLS_LOG(@"EULA accepted.");
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[NSString stringWithFormat:@"EULAacceptedAlready_userid%@", user.userId]];
        [AppDelegate goToViewAfterLogin];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if ((scrollView.contentSize.height - scrollView.frame.size.height) <= scrollView.contentOffset.y) {
        self.didScrollToTheEnd = YES;
    }
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
