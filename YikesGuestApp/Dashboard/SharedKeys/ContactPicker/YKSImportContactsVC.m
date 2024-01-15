//
//  YKSImportContactsVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/6/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSImportContactsVC.h"

#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>

@interface YKSImportContactsVC ()

@end

@implementation YKSImportContactsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.notNowButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.importContactsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    self.notNowButton.layer.cornerRadius = self.notNowButton.frame.size.width/2;
    self.notNowButton.clipsToBounds = YES;
    
    self.importContactsButton.layer.cornerRadius = self.importContactsButton.frame.size.width/2;
    self.importContactsButton.clipsToBounds = YES;
    
    if ([CNContactStore class]) {
        
        // iOS 9 and above
        
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (status == CNAuthorizationStatusAuthorized) {
            
            [self showContactPickerVCWithContacts:YES withAnimation:NO];
            
        } else if (status == CNAuthorizationStatusDenied ||
                   status == CNAuthorizationStatusRestricted) {
            
            [self showContactPickerVCWithContacts:NO withAnimation:NO];
        }
        
    } else {
        
        // older than iOS 9
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            
            [self showContactPickerVCWithContacts:YES withAnimation:NO];
            
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
                   ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted) {
            
            [self showContactPickerVCWithContacts:NO withAnimation:NO];
        }
        
    }
    
}

- (void)showContactPickerVCWithContacts:(BOOL)contactsAllowed withAnimation:(BOOL)animated  {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    YKSContactPickerVC *contactPickerVC = [storyboard instantiateViewControllerWithIdentifier:@"YKSContactPickerVC"];
    contactPickerVC.delegate = self.delegate;
    contactPickerVC.contactsAllowed = contactsAllowed;
    
    [self.navigationController setViewControllers:[NSArray arrayWithObject:contactPickerVC]
                                         animated:animated];
}

- (IBAction)cancelButtonTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)notNowButtonTapped:(id)sender {
    
    [self showContactPickerVCWithContacts:NO withAnimation:YES];
}

- (IBAction)importContactsButtonTapped:(id)sender {
    
    if ([CNContactStore class]) {
        
        // iOS 9 and above
        
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
           
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self showContactPickerVCWithContacts:YES withAnimation:YES];
                } else {
                    [self showContactPickerVCWithContacts:NO withAnimation:YES];
                }
            });
            
        }];
        
        
    } else {
        
        // older than iOS 9
        
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self showContactPickerVCWithContacts:YES withAnimation:YES];
                } else {
                    [self showContactPickerVCWithContacts:NO withAnimation:YES];
                }
            });
            
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
