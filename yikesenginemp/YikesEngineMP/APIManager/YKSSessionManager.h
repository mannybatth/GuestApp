//
//  YKSSessionManager.h
//  YKSApiKit
//
//  Created by Manny Singh on 4/5/15.
//  Copyright (c) 2015 yikes. All rights reserved.
//

/**
 *  Manages session states.
 *  Responsible for creating, restoring, & destroying session.
 */

#import <UIKit/UIKit.h>

@class YKSUser, YKSSession, YKSStay, YMan;

@interface YKSSessionManager : NSObject

+ (instancetype)sharedManager;

/**
 *  Create a new session for @param user
 */
+ (void)newSessionWithUser:(YKSUser *)user;

/**
 *  Return the current User from YKSSession.
 */
+ (YKSUser *)getCurrentUser;

/**
 *  Save @param user to current user session
 */
+ (void)setCurrentUser:(YKSUser *)user;

/**
 *  Returns list of current stays for user (if room number is assigned)
 */
+ (NSArray *)validUserStays;

/**
 *  Returns YES if there are any current (ie between checkin time and checkout time) 
 */
+ (BOOL)areThereCurrentStaysForYMan:(YMan *)yMan;


/**
 *  Returns list of primary yMen
 */
+ (NSSet *)allPrimaryYMen;


+ (NSSet *)allAmenities;

+ (BOOL)isRoomNameInStay:(NSString *)roomName;



/**
 *  Returns a Stay/Amenity associated with roomNumber
 *  WARNING: Result can be inaccurate if there are stays with equivalent roomNumber from different hotels
 */
+ (id)stayOrAmenityForRoomNumber:(NSString *)roomNumber;

+ (void)defaultAllConnectionStatuses;

/**
 *  Check to see if session is set.
 */
+ (BOOL)isSessionActive;

/**
 *  Saves YKSSession to cache.
 */
+ (void)saveActiveSessionToCache;

/**
 *  Clear session and delete YKSSession from cache.
 */
+ (void)destroySession;

/**
 *  Returns the session cookie
 */
+ (NSHTTPCookie *)getSessionCookie;

+ (BOOL)storeCurrentGuestAppUserEmail:(NSString *)email
                          andPassword:(NSString *)password;
+ (NSString *)currentGuestUsernameFromKeychains;
+ (NSString *)currentGuestPasswordFromKeychains;
+ (void)removeCurrentGuestCredentialsFromKeychains;

@end
