//
//  YKSModel.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/4/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Base Model class
 */

@import Mantle;

@interface YKSModel : MTLModel <NSCoding>

/**
 *  Returns a path for cache directory.
 *  Will create the path if it doesn't exist already.
 */
+ (NSString *)pathForRootObjectOfCacheName:(NSString *)cacheName;

/**
 *  Save @param rootObject to a file named @param cacheName.
 */
+ (void)saveWithRootObject:(id)rootObject withCacheName:(NSString *)cacheName;

/**
 *  Load rootObject from file named @param cacheName.
 */
+ (id)rootObjectWithCacheName:(NSString *)cacheName;

/**
 *  Removes rootObject from cache.
 */
+ (void)removeRootObjectWithCacheName:(NSString *)cacheName;

@end
