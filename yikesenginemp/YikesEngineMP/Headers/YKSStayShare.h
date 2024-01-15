//
//  YKSStayShare.h
//  yEngine
//
//  Created by Manny Singh on 9/2/15.
//
//

#import "YKSModel.h"

@import YikesSharedModel;

@class YKSUser, YKSStay;

@interface YKSStayShare : YKSModel <MTLJSONSerializing>

@property (nonatomic, strong) NSNumber * stayShareId;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, strong) YKSStay * stay;
@property (nonatomic, strong) YKSUser * primaryGuest;
@property (nonatomic, strong) YKSUser * secondaryGuest;

/**
 *  Parse JSON array into list of YKSStayShare objects.
 */
+ (NSArray *)newStaySharesFromJSON:(NSArray *)JSONArray error:(NSError *__autoreleasing *)error;

/**
 *  Parse JSON dictionary into single YKSStayShare object.
 */
+ (YKSStayShare *)newStayShareFromJSON:(NSDictionary *)JSONDictionary error:(NSError *__autoreleasing *)error;

@end
