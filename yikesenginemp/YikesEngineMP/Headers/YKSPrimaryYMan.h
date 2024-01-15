//
//  YKSPrimaryYMan.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@class YKSStay;

@interface YKSPrimaryYMan : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString * macAddress;
@property (nonatomic) BOOL isMainRoom;

@property (nonatomic, strong) YKSStay * stay;

/**
 *  Parse JSON array into list of PrimaryYMan objects.
 */
+ (NSArray *)newPrimaryYMenFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single PrimaryYMan object.
 */
+ (YKSPrimaryYMan *)newPrimaryYManFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

/**
 *  Returns a raw binary version of the mac_address rather than the string
 */
- (NSData *)binaryMacAddress;


@end
