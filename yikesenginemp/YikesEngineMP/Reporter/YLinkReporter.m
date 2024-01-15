//
//  YLinkReporter.m
//  Pods
//
//  Created by Alexandar Dimitrov on 2015-01-16.
//
//

#import "YLinkReporter.h"

@implementation YLinkReporter


- (id)init {
    self = [super init];
    
    if (self) {
        self.writtenToFile = NO;
        self.numberScansGA = 0;
    }
    
    
    return self;
}


@end
