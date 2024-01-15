//
//  YKSCountryPicker.m
//  YikesGuestApp
//
//  Created by Manny Singh on 7/23/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSCountryPicker.h"
@import HexColors;

@interface YKSCountryPicker () <UISearchResultsUpdating>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *allCountries;
@property (strong, nonatomic) NSArray *filteredCountries;

@end

@implementation YKSCountryPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.navigationController.view.backgroundColor = [UIColor colorWithHexString:@"5F9318"];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                 NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14.0f],
                                                                                                 NSForegroundColorAttributeName:[UIColor whiteColor]
                                                                                                 }];
    
    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search"
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
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"search_icon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [self.searchController.searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    
    self.navigationItem.titleView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    
    [self loadCountries];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self scrollToSelectedCountry];
}

- (IBAction)backButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)scrollToSelectedCountry {
    
    if (!self.selectedCountry) {
        return;
    }
    
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"SELF.countryCode contains[cd] %@",
                                    self.selectedCountry.countryCode];
    
    NSArray *results = [self.allCountries filteredArrayUsingPredicate:resultPredicate];
    
    if (results.count > 0) {
        YKSCountry *selectedCountry = results.firstObject;
        NSUInteger index = [self.allCountries indexOfObject:selectedCountry];
        
        NSIndexPath *ip = [NSIndexPath indexPathForItem:index inSection:0];
        [self.tableView selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    
}

- (void)loadCountries {
    
    NSMutableArray *countries = [NSMutableArray array];
    
    for (NSString *code in [NSLocale ISOCountryCodes]) {
        
        NSString *countryName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:code];
        
        YKSCountry *country = [[YKSCountry alloc] init];
        country.countryCode = code;
        country.countryName = countryName;
        [countries addObject:country];
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"countryName" ascending:YES];
    
    self.allCountries = [NSArray arrayWithArray:[countries sortedArrayUsingDescriptors:@[sort]]];
}

- (void)filterCountriesByKeyword:(NSString *)keyword {
    
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"SELF.countryName contains[cd] %@",
                                    keyword];
    
    self.filteredCountries = [self.allCountries filteredArrayUsingPredicate:resultPredicate];
}

//- (NSLocale *)selectedLocale
//{
//    NSString *countryCode = self.selectedCountryCode;
//    if (countryCode)
//    {
//        NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: countryCode}];
//        return [NSLocale localeWithLocaleIdentifier:identifier];
//    }
//    return nil;
//}


#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *keyword = searchController.searchBar.text;
    
    if (keyword.length > 0) {
        [self filterCountriesByKeyword:keyword];
    } else {
        self.filteredCountries = nil;
    }
    
    [self.tableView reloadData];
    
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.filteredCountries) {
        return self.filteredCountries.count;
    }
    return self.allCountries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YKSCountryTC" forIndexPath:indexPath];
    
    YKSCountry *country;
    if (self.filteredCountries) {
        country = [self.filteredCountries objectAtIndex:indexPath.row];
    } else {
        country = [self.allCountries objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = country.countryName;
    
    if ([country.countryCode isEqualToString:self.selectedCountry.countryCode]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView setBackgroundColor:[UIColor colorWithHexString:@"5F9318" alpha:0.75]];
    [cell setSelectedBackgroundView:bgColorView];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YKSCountry *selectedCountry;
    if (self.filteredCountries) {
        selectedCountry = [self.filteredCountries objectAtIndex:indexPath.row];
    } else {
        selectedCountry = [self.allCountries objectAtIndex:indexPath.row];
    }
    
    self.selectedCountry = selectedCountry;
    
    [self.tableView reloadData];
    
    self.searchController.active = NO;
    [self.delegate countryController:self didSelectCountry:self.selectedCountry];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
