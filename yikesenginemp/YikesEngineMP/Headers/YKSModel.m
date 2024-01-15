//
//  YKSModel.m
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

#import "YKSModel.h"
#import "YKSInternalConstants.h"

@implementation YKSModel

+ (NSString *)pathForRootObjectOfCacheName:(NSString *)cacheName
{
    cacheName = [cacheName stringByReplacingOccurrencesOfString:@"/" withString:@"_$$_"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cacheDirectory = [documentsDirectory stringByAppendingPathComponent:yksModelCacheDirectoryFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dataPath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheName]];
    return dataPath;
}

+ (void)saveWithRootObject:(id)rootObject
             withCacheName:(NSString *)cacheName
{
    NSString *path = [self pathForRootObjectOfCacheName:cacheName];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

+ (id)rootObjectWithCacheName:(NSString *)cacheName
{
    NSString *path = [self pathForRootObjectOfCacheName:cacheName];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void)removeRootObjectWithCacheName:(NSString *)cacheName
{
    NSString *path = [self pathForRootObjectOfCacheName:cacheName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

@end
