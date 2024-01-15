//
//  Stay.m
//  yikes
//
//  Created by Roger on 8/19/14.
//  Copyright (c) 2014 Yamm Software Inc. All rights reserved.
//

#import "UserStay.h"

@implementation UserStay

- (BOOL) isActive {
    if (!self.is_active) {
        return NO;
    }
    else {
        return [self isBetweenDate:self.arrival_date andDate:self.depart_date];
    }
}

- (BOOL)isBetweenDate:(NSDate *)earlierDate andDate:(NSDate *)laterDate
{
    NSDate *now = [NSDate date];
    
    // first check that we are later than the earlierDate.
    if ([now compare:earlierDate] == NSOrderedDescending) {
        
        // next check that we are earlier than the laterData
        if ( [now compare:laterDate] == NSOrderedAscending ) {
            return YES;
        }
    }
    
    // otherwise we are not
    return NO;
}

- (NSSet *)primary_ymen_mac_addresses {
    return nil;
}

@end
