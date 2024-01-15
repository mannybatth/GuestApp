//
//  BinaryHelper.h
//  YikesTester
//
//  Created by Elliot on 2014-04-02.
//  Copyright (c) 2014 Yamm Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YKSBinaryHelper : NSObject

+(BOOL)isCustomTokenValid:(NSString *)token;
+(NSData *)binaryFromHexString:(NSString *)hexString;
+(NSString *)paddedSpacedHexStringFromBinary:(NSData *)data ofByteLength:(NSUInteger)numberOfBytes withPaddingChar:(char)padChar;
+(NSString *)hexStringFromBinary:(NSData *)data;

+(void)testCustomTokenValidator;
+(void)testBinaryFromHexString;
+(void)testPaddedSpacedString;
+ (NSData *)randomDataOfLength:(size_t)length;

@end
