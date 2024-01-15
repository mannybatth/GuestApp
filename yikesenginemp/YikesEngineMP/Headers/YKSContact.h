//
//  YKSContact.h
//  YikesGuestApp
//
//  Created by Manny Singh on 10/26/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSModel.h"

@class YKSUser;

@interface YKSContact : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSNumber * contactId;
@property (nonatomic, strong) YKSUser * user;

/**
 *  Parse JSON array into list of YKSContact objects.
 */
+ (NSArray *)newContactsFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single YKSContact object.
 */
+ (YKSContact *)newContactFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
