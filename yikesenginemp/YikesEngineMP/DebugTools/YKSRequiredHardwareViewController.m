//
//  YKSRequiredHardwareViewController.m
//  yikes
//
//  Created by royksopp on 2015-05-13.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSRequiredHardwareViewController.h"
#import "YKSRequiredHardwareNotificationCenter.h"
#import "YKSRequiredHardwareTableViewCell.h"
#import "Colours.h"

@import YikesSharedModel;

@interface YKSRequiredHardwareViewController () <UITableViewDataSource, UITableViewDelegate,
YKSRequiredHardwareNotificatioCenterNewMessageDelegate>

@property (strong, nonatomic) NSArray *requiredHardwareCurrentMessagesLocalNSArray;

@end

@implementation YKSRequiredHardwareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.missingRequiredHardwareTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.missingRequiredHardwareTableView setSeparatorColor:[UIColor clearColor]];
    
    [self.missingRequiredHardwareTableView setDataSource:self];
    [self.missingRequiredHardwareTableView setDelegate:self];
    
    self.view.backgroundColor = [UIColor grapeColor];
    self.missingRequiredHardwareTableView.backgroundColor = [UIColor grapeColor];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [YKSRequiredHardwareNotificationCenter sharedCenter].requiredHardwareMessagesAvailableDelegate = self;
    
    [[YKSRequiredHardwareNotificationCenter sharedCenter] readRequiredHardwareState];
}


#pragma mark - YKSRequiredHardwareNotificatioCenterNewMessageDelegate
- (void)requiredHardwareNewMessagesAvailable:(NSMutableSet *)currentStates {
    
    if ([currentStates containsObject:@(kYKSBackgroundAppRefreshService)]
        || [currentStates containsObject:@(kYKSLocationService)]) {
        self.openSettingsButton.hidden = NO;
    }
    else if ([currentStates count] > 0) {
        self.openSettingsButton.hidden = YES;
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            //
        }];
    }
    
    self.requiredHardwareCurrentMessagesLocalNSArray = [[YKSRequiredHardwareNotificationCenter sharedCenter] requireHardwareCurrentMessages];
    
    [self.missingRequiredHardwareTableView reloadData];
}



#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 18;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.requiredHardwareCurrentMessagesLocalNSArray count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSRequiredHardwareTableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"missingReqHardwareCell" forIndexPath:indexPath];
    NSString *missingReqHardwareMessage = [self.requiredHardwareCurrentMessagesLocalNSArray objectAtIndex:indexPath.row];
    
    cell.missingRequiredHardwareMessage.text = missingReqHardwareMessage;
    
    cell.backgroundColor = [UIColor grapeColor];
    
    return cell;
}


#pragma mark - Actions

- (IBAction)openSettings:(id)sender {
    
    //TODO: disable for iOS 7
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
