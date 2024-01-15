//
//  BinaryHelper.m
//  YikesTester
//
//  Created by Elliot on 2014-04-02.
//  Copyright (c) 2014 Yamm Software. All rights reserved.
//

#import "YKSBinaryHelper.h"

@implementation YKSBinaryHelper

+(BOOL)isCustomTokenValid:(NSString *)token {
    
    //first check that length is less than 12 and not 0
    if (token.length > 12 || token.length == 0)
        return NO;
    
    NSCharacterSet *badChars = [[NSCharacterSet
                                 characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
    
    BOOL isValid = (NSNotFound == [token rangeOfCharacterFromSet:badChars].location);
    
    return isValid;
}

+(void)testCustomTokenValidator {
    
    NSArray * tests = @[@"12443443", @"EEEFFff22", @"ww22", @"112233445566w", @"123ffe"];
    
    int i = 0;
    for (NSString * test in tests) {
        NSLog(@"Test %i: Is %@ valid? %@", i, test, [YKSBinaryHelper isCustomTokenValid:test]? @"YES" : @"NO");
        i++;
    }
    
}

+(NSData *)binaryFromHexString:(NSString *)hexString {

    if (!hexString) {
        return nil;
    }
    
    //Add padding in case the length is odd, eg 1123ffe --> 01123ffe, otherwise the alignment is off
    NSMutableString * paddedString = [NSMutableString stringWithString:hexString];
    
    if ([hexString length] % 2 != 0) {
        paddedString = [NSMutableString stringWithFormat:@"0%@", paddedString];
    }
    
    const char *chars = [paddedString UTF8String];
    int i = 0;
    NSUInteger len = paddedString.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

+(void)testBinaryFromHexString {
   
    NSArray * tests = @[@"12443443", @"EEEFFff22", @"ww22", @"112233445566w", @"123ffe", @"C0FFEEFACE11"];
    
    int i = 0;
    for (NSString * test in tests) {
       
        NSData * token = [YKSBinaryHelper binaryFromHexString:test];
        NSLog(@"Before: %@ After %@", test, token);
        
        i++;
    }
    
}



+(NSString *)hexStringFromBinary:(NSData *)data {
   
    NSUInteger capacity = [data length] * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [data bytes];
    NSInteger i;
    for (i=0; i<[data length]; ++i) {
        [stringBuffer appendFormat:@"%02lX", (unsigned long)dataBuffer[i]];
    }
    
    return [NSString stringWithString:stringBuffer];
    
}


//returns a padded Hex string with each byte separated by a space. If the given data exceeds the number of paddding bytes, it is not truncated.
// passing in a null character '\0' as the padding character causes the result to be returned unpadded
+(NSString *)paddedSpacedHexStringFromBinary:(NSData *)data ofByteLength:(NSUInteger)numberOfBytes withPaddingChar:(char)padChar {
   
    NSString * hexString = [YKSBinaryHelper hexStringFromBinary:data];

    //DLog(@"Hex string: %@ len: %i", hexString, [hexString length]);
    
    NSMutableString * paddedString = [NSMutableString stringWithString:@""];
    
    int hexStringLength = (int)[hexString length];
    
    for (int i = hexStringLength-1; i >= 0; i -= 2) {
        paddedString = [NSMutableString stringWithFormat:@"%c%@", [hexString characterAtIndex:i], paddedString]; //prepend i
        paddedString = [NSMutableString stringWithFormat:@"%c%@", [hexString characterAtIndex:i - 1], paddedString]; //prepend i -1
        paddedString = [NSMutableString stringWithFormat:@" %@", paddedString]; //prepend space
        
    }
    
    //strip extra space added
    paddedString = [NSMutableString stringWithString:[paddedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

    if (padChar) {
        
        NSInteger remaining = numberOfBytes - (hexStringLength/2);
        
        if (remaining > 0) {
            for (int i = 0; i < remaining; i++) {
                paddedString = [NSMutableString stringWithFormat:@"%c%c %@", padChar, padChar, paddedString];
            }
            
        }
    
    }
    
    return [NSString stringWithFormat:@"%@", paddedString];
    
}

+(void)testPaddedSpacedString {
    
    NSArray * tests = @[@"12443443", @"EEEFFff22", @"22", @"112233445566", @"01123ffe", @"eee10"];
    
    int i = 0;
    for (NSString * test in tests) {
        
        NSData * token = [YKSBinaryHelper binaryFromHexString:test];
        NSString * padded = [YKSBinaryHelper paddedSpacedHexStringFromBinary:token ofByteLength:6 withPaddingChar:'0'];
        NSLog(@"Original: %@ Binary: %@ Padded %@", test, token, padded);
        
        i++;
    }
    
}

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    
    int result = 0;
    result = SecRandomCopyBytes(kSecRandomDefault,
                                length,
                                data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d",
             errno);
    
    return data;
}




@end
