//
//  YKSYManTableConnectionsViewController.m
//  yikes
//
//  Created by royksopp on 2015-05-08.
//  Copyright (c) 2015 Yamm Software Inc. All rights reserved.
//

#import "YKSYManTableConnectionsViewController.h"
#import "YKSScanningYManTableViewCell.h"
#import "YKSDebugManager.h"
#import "YKSYManConnection.h"
#import "YKSBinaryHelper.h"

@interface YKSYManTableConnectionsViewController () <UITableViewDataSource, UITableViewDelegate, YKSDebugConsolePrimaryYmanStatusDelegate>

@property (nonatomic, strong) NSMutableArray *testYManScanningArray;

@end

@implementation YKSYManTableConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.scanningYManTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.scanningYManTableView setSeparatorColor:[UIColor clearColor]];

    
    [self.scanningYManTableView setDataSource:self];
    [self.scanningYManTableView setDelegate:self];
    [[YKSDebugManager sharedManager] setPrimaryYManStatusDelegate:self];
}



#pragma mark
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 18;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    
//    if (0 == section) {
//        return @"yMan";
//    }
//    
//    return @"";
//}

#pragma mark
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSMutableArray *connections = [[YKSDebugManager sharedManager] primaryYManConnections];
    return [connections count];
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSScanningYManTableViewCell * cell;
    
    NSMutableArray *connections = [[YKSDebugManager sharedManager] primaryYManConnections];
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"yManCell" forIndexPath:indexPath];
    
    YKSYManConnection *oneYManConnection = [connections objectAtIndex:indexPath.row];
    
    cell.yManMacAddressLabel.text = [YKSBinaryHelper hexStringFromBinary:oneYManConnection.macAddress];
    
    BOOL yManConnected = [oneYManConnection isConnected];
    
    if (yManConnected) {
        // show green dot and hide spinner
        cell.yManConnectionDotImageView.hidden = NO;
        [cell.yManScanActivityIndicator stopAnimating];
        cell.yManScanActivityIndicator.hidden = YES;
    }
    else {
        // show spinner and hide green dot
        cell.yManConnectionDotImageView.hidden = YES;
        cell.yManScanActivityIndicator.hidden = NO;
        // Make the spinner smaller
        cell.yManScanActivityIndicator.transform = CGAffineTransformMakeScale(0.7, 0.7);
        [cell.yManScanActivityIndicator startAnimating];
    }
    
    return cell;
}


#pragma mark - YKSDebugConsolePrimaryYmanStatusDelegate

- (void)primaryYManDataAvailable {
    //TODO: reload table view with primary yMan data
    [self.scanningYManTableView reloadData];
}


#pragma mark


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc {
    [[YKSDebugManager sharedManager] setPrimaryYManStatusDelegate:nil];
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
