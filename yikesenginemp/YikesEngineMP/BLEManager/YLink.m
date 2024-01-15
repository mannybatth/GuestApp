//
//  YLink.m
//  Pods
//
//  Created by Elliot Sinyor on 2015-03-31.
//
//

#import "YLink.h"

@implementation YLink

-(instancetype)initWithMacAddress:(NSData *)address andPrimaryYMAN:(YMan *)primaryYMAN {
   
    self = [super init];
   
    if (self) {
        
        _macAddress = address;
        _primaryYMan = primaryYMAN;
        
    }
   
    return self;
}


-(BOOL)isEqual:(id)object {
  
    if (![object isKindOfClass:[YLink class]]) {
        return NO;
    }
    
    YLink * comparison = (YLink *)object;
    if ([comparison.macAddress isEqualToData:self.macAddress]) {
        return YES;
    } else {
        return NO;
    }
    
}


//Need to also provide this since it's used along with isEqual in determining equality for set membership
-(NSUInteger)hash {
   
    return [self.macAddress hash];
    
}

-(NSString *)description {
   
    return [NSString stringWithFormat:@"YLink: %@, Peripheral: %@", self.macAddress, self.peripheral];
    
}


@end
