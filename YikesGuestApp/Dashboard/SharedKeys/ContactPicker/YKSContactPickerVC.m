//
//  YKSContactPickerVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/2/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSContactPickerVC.h"
#import "YKSContactPickerTC.h"
#import "AppManager.h"

@import YikesSharedModel;

#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>

typedef NS_ENUM(NSUInteger, TabType) {
    kAllContactsTab,
    kRecentContactsTab,
};

@interface YKSContactPickerVC () <UISearchResultsUpdating, YKSContactPickerTCDelegate>

@property (strong, nonatomic) UISearchController *searchController;

@property (strong, nonatomic) NSArray *contactsList;

@property (strong, nonatomic) NSArray *contactsFromDevice;
@property (strong, nonatomic) NSArray *contactsImageData;

@property (strong, nonatomic) NSArray *filteredContacts;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@property (nonatomic) TabType selectedTab;

@end

@implementation YKSContactPickerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.tabsContainerViewHeightConstraint.constant = 0;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.selectedTab = kAllContactsTab;
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                 NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14.0f],
                                                                                                 NSForegroundColorAttributeName:[UIColor whiteColor]
                                                                                                 }];
    
    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search or type email"
                                                                                attributes:@{
                                                                                             NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14.0f],
                                                                                             NSForegroundColorAttributeName:[UIColor whiteColor]
                                                                                             }];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setAttributedPlaceholder:attributedPlaceholder];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    [self.searchController.searchBar setTintColor:[UIColor whiteColor]];
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.searchTextPositionAdjustment = UIOffsetMake(-15.0f, 0.0f);
    [self.searchController.searchBar setPositionAdjustment:UIOffsetMake(-5.0f, 1.0f) forSearchBarIcon:UISearchBarIconClear];
    [self.searchController.searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"search_bar_clear"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"search_bar_clear_selected"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateSelected];
    self.searchController.searchBar.keyboardType = UIKeyboardTypeEmailAddress;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.searchBarContainerView addSubview:self.searchController.searchBar];
    
    // status bar background when searching
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64.0f)];
    view.backgroundColor = [UIColor colorWithHexString:@"7CBE31"];
    [self.view insertSubview:view belowSubview:self.searchBarContainerView];
    
    self.allContactsTabButton.layer.borderColor = [UIColor colorWithHexString:@"E3E3E3"].CGColor;
    self.allContactsTabButton.layer.borderWidth = 1.0f;
    self.recentContactsTabButton.layer.borderColor = [UIColor colorWithHexString:@"E3E3E3"].CGColor;
    self.recentContactsTabButton.layer.borderWidth = 1.0f;
    self.tabsContainerView.clipsToBounds = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    if (self.contactsAllowed) {
        
        // Fetch contacts asynchronously
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self fetchContacts];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadTableView];
            });
        });
    }
    
    [[YikesEngine sharedEngine] getRecentContactsWithSuccess:^(NSArray<YKSContactInfo *> *contacts) {
        
        [self reloadTableView];
        
    } failure:^(YKSError *error) {
        
    }];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.searchController.searchBar sizeToFit];
}

- (void)reloadTableView {
    
    if (self.selectedTab == kAllContactsTab) {
        self.contactsList = self.contactsFromDevice;
    } else {
        self.contactsList = [YikesEngine sharedEngine].userInfo.recentContacts;
    }
    [self.tableView reloadData];
}

- (IBAction)allContactsTabSelected:(id)sender {
    
    if (self.selectedTab == kAllContactsTab) return;
    
    self.selectedTab = kAllContactsTab;
    
    [self.view layoutIfNeeded];
    
    self.selectedBarViewTrailingConstraint.active = NO;
    self.selectedBarViewLeadingConstraint.active = YES;
    [UIView animateWithDuration:0.15f delay:0.0f options:(UIViewAnimationOptionCurveEaseIn)
                     animations:^{
                         [self.view layoutIfNeeded];
    } completion:nil];
    
    [self deselectSelectedIndexPath];
    [self reloadTableView];
}

- (IBAction)recentContactsTabSelected:(id)sender {
    
    if (self.selectedTab == kRecentContactsTab) return;
    
    self.selectedTab = kRecentContactsTab;
    
    [self.view layoutIfNeeded];
    
    self.selectedBarViewLeadingConstraint.active = NO;
    self.selectedBarViewTrailingConstraint.active = YES;
    [UIView animateWithDuration:0.15f delay:0.0f options:(UIViewAnimationOptionCurveEaseIn)
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:nil];
    
    [self deselectSelectedIndexPath];
    [self reloadTableView];
}

- (void)dismissKeyboard {
    [self.searchController.view endEditing:YES];
}

- (IBAction)cancelButtonTapped:(id)sender {
    
    [self.searchController dismissViewControllerAnimated:NO completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonTapped:(id)sender {
    
    if (self.selectedIndexPath) {
        
        YKSContactInfo *selectedContactInfo = [self contactInfoForIndexPath:self.selectedIndexPath];
        [self dismissContactPickerWithContactInfo:selectedContactInfo];
        
    }
}

- (void)dismissContactPickerWithContactInfo:(YKSContactInfo *)contactInfo {
    
    if ([self.delegate respondsToSelector:@selector(didSelectContactWithInfo:)]) {
        [self.delegate didSelectContactWithInfo:contactInfo];
    }
    
    [self.searchController dismissViewControllerAnimated:NO completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (YKSContactInfo *)contactInfoForIndexPath:(NSIndexPath *)indexPath {
    
    if (self.filteredContacts) {
        return [self.filteredContacts objectAtIndex:indexPath.row];
    } else {
        return [self.contactsList objectAtIndex:indexPath.row];
    }
}

- (void)deselectSelectedIndexPath {
    
    if (self.selectedIndexPath) {
        
        YKSContactPickerTC *cell = [self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setSelected:NO];
        
        [self.tableView deselectRowAtIndexPath:self.selectedIndexPath animated:YES];
        self.selectedIndexPath = nil;
        
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        if (self.selectedTab == kRecentContactsTab) {
            cell.removeContactButton.hidden = NO;
        } else {
            cell.removeContactButton.hidden = YES;
        }
        
    }
}

- (void)filterContactsByKeyword:(NSString *)keyword {
    
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"SELF.user.email contains[cd] %@ OR SELF.user.firstName contains[cd] %@ OR SELF.user.lastName contains[cd] %@",
                                    keyword, keyword, keyword];
    
    self.filteredContacts = [self.contactsList filteredArrayUsingPredicate:resultPredicate];
    
    if (self.filteredContacts.count == 0) {
        
        if ([NSString isValidEmail:keyword]) {
            
            NSDictionary *contactInfoDict = @{
                                              @"user": @{
                                                      @"email": keyword
                                                      }
                                              };
            YKSContactInfo *contactInfo = [YKSContactInfo newWithJSONDictionary:contactInfoDict];
            self.filteredContacts = @[contactInfo];
        }
        
    }
    
}

#pragma mark UIKeyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

#pragma mark YKSContactPickerTCDelegate

- (void)removeContactButtonTouched:(YKSContactPickerTC *)cell {
    
    PKAlertViewController *alert = [PKAlertViewController alertControllerWithConfigurationBlock:^(PKAlertControllerConfiguration *configuration) {
        
        configuration.title = @"Remove from recents";
        configuration.message = @"Are you sure you want to remove this contact from recents?";
        
        [configuration addAction:[PKAlertAction cancelAction]];
        [configuration addAction:[PKAlertAction actionWithTitle:@"Yes" handler:^(PKAlertAction *action, BOOL closed) {
            
            if (closed) {
                
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                [SVProgressHUD showWithStatus:@"Removing contact.."];
                
                [[YikesEngine sharedEngine] removeRecentContact:cell.contactInfo success:^{
                    
                    [self reloadTableView];
                    [SVProgressHUD dismiss];
                    
                } failure:^(YKSError *error) {
                    [SVProgressHUD showErrorWithStatus:error.description];
                }];
                
            }
            
        }]];
        
    }];
    [self presentViewController:alert animated:YES completion:nil];
    
}


#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *keyword = searchController.searchBar.text;
    
    if (keyword.length > 0) {
        
        [self deselectSelectedIndexPath];
        [self filterContactsByKeyword:keyword];
        [self.tableView reloadData];
        
    } else {
        
        [self deselectSelectedIndexPath];
        self.filteredContacts = nil;
        [self.tableView reloadData];
        
    }
    
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.filteredContacts) {
        return self.filteredContacts.count;
    }
    return self.contactsList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 62.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSContactPickerTC *cell = (YKSContactPickerTC *)[tableView dequeueReusableCellWithIdentifier:@"YKSContactPickerTC" forIndexPath:indexPath];
    
    YKSContactInfo *contactInfo;
    if (self.filteredContacts) {
        contactInfo = [self.filteredContacts objectAtIndex:indexPath.row];
    } else {
        contactInfo = [self.contactsList objectAtIndex:indexPath.row];
    }
    
    cell.delegate = self;
    [cell setupViewWithContactInfo:contactInfo];
    
    [cell.contactAvatarImageView setImage:[UIImage imageNamed:@"default_avatar_s"]];
    
    [self.contactsImageData enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull imageDataDict, NSUInteger idx, BOOL * _Nonnull stop) {
       
        YKSContactInfo *ci = imageDataDict[@"contactInfo"];
        if ([ci isEqual:contactInfo]) {
            [cell.contactAvatarImageView setImage:[UIImage imageWithData:imageDataDict[@"imageData"]]];
        }
        
    }];
    
    if ([indexPath isEqual:self.selectedIndexPath]) {
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setSelected:YES];
        cell.removeContactButton.hidden = YES;
        
    } else {
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setSelected:NO];
        
        if (self.selectedTab == kRecentContactsTab) {
            cell.removeContactButton.hidden = NO;
        } else {
            cell.removeContactButton.hidden = YES;
        }
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.selectedIndexPath isEqual:indexPath]) {
        [self deselectSelectedIndexPath];
        return;
    }
    
    [self deselectSelectedIndexPath];
    
    self.selectedIndexPath = indexPath;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    YKSContactPickerTC *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.removeContactButton.hidden = YES;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark Contacts framework

- (void)fetchContacts {
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    NSMutableArray *contactsImageData = [[NSMutableArray alloc] init];
    
    if ([CNContactStore class]) {
        
        // iOS 9 and above
        
        NSArray *keysToFetch = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],
                                 CNContactImageDataKey,
                                 CNContactPhoneNumbersKey,
                                 CNContactEmailAddressesKey];
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
        CNContactStore *store = [[CNContactStore alloc] init];
        
        NSError *error;
        [store enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            
            if (contact.emailAddresses.count > 0) {
                
                CNLabeledValue *emailLabel = [contact.emailAddresses firstObject];
                
                NSDictionary *contactDict = @{
                                              @"user": @{
                                                      @"first_name": contact.givenName,
                                                      @"last_name": contact.familyName,
                                                      @"email": emailLabel.value
                                                      }
                                              };
                YKSContactInfo *contactInfo = [YKSContactInfo newWithJSONDictionary:contactDict];
                [contacts addObject:contactInfo];
                
                if (contact.imageData) {
                    NSDictionary *imageData = @{
                                                @"contactInfo": contactInfo,
                                                @"imageData": contact.imageData
                                                };
                    [contactsImageData addObject:imageData];
                }
                
            }
            
        }];
        
        if (error) {
            CLSLog(@"Error getting contacts: %@", error);
        }
        
    } else {
        
        // less than iOS 9
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            
            ABAddressBookRef addressBook = ABAddressBookCreate( );
            CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
            CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
            
            for ( int i = 0; i < nPeople; i++ ) {
                
                ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
                
                NSString *firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
                NSString *lastName  = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
                
                ABMultiValueRef emailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
                CFIndex numberOfEmails = ABMultiValueGetCount(emailAddresses);
                if (numberOfEmails > 0) {
                    NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailAddresses, 0));
                    
                    NSDictionary *contactDict = @{
                                                  @"user": @{
                                                          @"first_name": firstName ? firstName : @"",
                                                          @"last_name": lastName ? lastName : @"",
                                                          @"email": email ? email : @""
                                                          }
                                                  };
                    YKSContactInfo *contactInfo = [YKSContactInfo newWithJSONDictionary:contactDict];
                    [contacts addObject:contactInfo];
                    
                    NSData *imgData = CFBridgingRelease(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail));
                    if (imgData) {
                        NSDictionary *imageData = @{
                                                    @"contactInfo": contactInfo,
                                                    @"imageData": imgData
                                                    };
                        [contactsImageData addObject:imageData];
                    }
                    
                }
                
                CFRelease(emailAddresses);
            }
            
            CFRelease(allPeople);
            CFRelease(addressBook);
            
        }
        
    }
    
    self.contactsFromDevice = [NSArray arrayWithArray:contacts];
    self.contactsImageData = [NSArray arrayWithArray:contactsImageData];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
