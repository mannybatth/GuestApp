//
//  YikesBLEConstants.h
//  
//
//  Created by Elliot on 2/12/2014.
//
//

#ifndef _YikesBLEConstants_h
#define _YikesBLEConstants_h

//NB: "CHAR" is short for CHARACTERISTIC

//Message Service

// peripheral names
#define kDeviceYLink @"yLink"
#define kDeviceYMAN @"yMAN"
#define kDeviceElevatorYLink @"elevator"

// flow event
#define kEventNotFound @"Not Found"

//iBeacon
#define YIKES_TEST_BEACON @"3E2CE80C-E4B7-4F5D-BA52-8E61427B6EC9"   // production
//#define YIKES_TEST_BEACON @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" // test
//#define YIKES_TEST_BEACON @"74278BDA-B644-4520-8F0C-720EAF059935" // test
#define YIKES_TEST_BEACON_IDENTIFIER @"YIKES TEST BEACON"

//YLink
#define YLINK_ADV_SERVICE_BASE_UUID @"49FEB2859514B6629832"
#define YLINK_SERVICE_UUID @"C3221178-2E83-40E2-9F12-F07B57A77E1F"

//CoreMotion / Inactivity
#ifdef DEBUG
#define INACTIVITY_TIMEOUT 2000
#else
#define INACTIVITY_TIMEOUT 120
#endif
#define INACTIVITY_SENSITIVITY 0.05 //0.01 = even if held in hand, it's moving. if sitting on a desk, it's stationary

// Common-Area yLinks connection threshold
#define ELEVATOR_YLINK_THRESHOLD_RSSI -80

#define kStaticStayToken @"c0ffeeface11"
#define kStaticTrackID @"112233445566"

//#define YLINK_CHAR_UUID @"DD90C297-C27D-4316-AEFB-4EEE77246FD6" //from: https://yikesdev.atlassian.net/wiki/pages/viewpage.action?pageId=1573029
#define YLINK_READ_CHAR_UUID @"6795137C-F551-43AF-AC71-6340C5CFD080"
#define YLINK_WRITE_CHAR_UUID @"06F87DA4-6264-4C8F-9ADB-D077380CEFA9"

#define YLINK_REPORTING_SESSION_DISCONNECT_TIMER 3

// message ID is 17 - so hex is 0x11
#define YLINK_ROOMAUTH_MSG_ID 0x11
#define YLINK_RANGING_INTERVAL 10

#define YLINK_DISCOVERY_TIME 5

//BLE Engine version number for yMAN
#define BLE_ENGINE_VERSION 0x05

// Make it long enough to allow the yMan to yLink process to complete and the yLink to start advertising (~2.5s)
#define YLINK_NO_ADV_FOUND_TIME 9
#define YLINK_RANGING_TIMEOUT 5*60
#define YLINK_DEFAULT_ROOMAUTH_EXPIRATION 15

#define YLINK_ZERO_TRACKID_PAUSE_TIME 30


#define NEW_ROOM_AUTH_CYCLE_TIME 4
#define SHORT_NEW_ROOM_AUTH_CYCLE_TIME 2

//Scan Timer Interval
#define SCAN_TIMER_INTERVAL 1.0
#define SCAN_TIMER_INTERVAL_STATIONARY 5.0

// Elevator Constants
#define NEW_ELEVATOR_SCAN_TIMEOUT 1.0
#define ELEVATOR_CONNECT_TIMEOUT 5
#define ELEVATOR_CLOSEST_SCAN_TIME 0.7

//yMan2yPhone from https://yikesdev.atlassian.net/wiki/display/YK/MSG-01+yMan2yPhone+Advert
#define YMAN_SERVICE_UUID @"F7E66311-D667-4C2F-A1DD-BD3BF1B40DB6"
#define YMAN_CHAR_UUID @"D6F53993-1857-4663-99F4-AB045B3CDC56"

#define YMAN_YPHONEID_MSG_ID 0x02
#define YMAN_ROOMAUTH_MSG_ID_V1toV3 0x09
#define YMAN_ROOMAUTH_MSG_ID 0x20

#define YMAN_RENEWAUTH_MSG_ID 0x50


#define BEGIN_SCANNING_FOR_YIKES_HARDWARE_TIMEOUT 4

#define YMAN_RECONNECT_TRIALS 2
#define YLINK_RECONNECT_TRIALS 2

#define YMAN_CONNECTION_ATTEMPT_TIMEOUT 6.5

#ifdef DEBUG
#define YMAN_BLACKLIST_DURATION 15.0
#else
#define YMAN_BLACKLIST_DURATION 5.0
#endif

// Try 10 - 6 doesn't seem to be long enough for Guest App > yMAN connection request
#define YMAN_DISCONNECT_TIMEOUT 6
#define YMAN_CLOSEST_SCAN_TIME 1.6

//Hotel App service
#define HOTEL_SERVICE_UUID @"C2289CF1-C8E3-4F59-BC88-1520B0D1A12A"

//Services for 2014-04-11 test:
#define TALON_SERVICE_UUID @"11223344-5566-49FE-B285-9514B6629832"
#define TALON_CHAR_UUID @"06F87DA4-6264-4C8F-9ADB-D077380CEFA9"

#define AUTH_SERVICE_UUID @"e115"
#define NAME_CHAR_UUID @"945e"

#define AUTH_TOKEN_CHAR_UUID @"a074"
#define AUTH_TOKEN_VALUE @"A7C60EFA-33F0-45D0-B50B-80DD2A2FB9A0"

#define RESERVATION_TOKEN_CHAR_UUID @"fa55"
#define RESERVATION_TOKEN_VALUE @"YLE1993RZ10"

#define GUEST_NAME_CHAR_UUID @"945e"

#define FIRSTNAME_CHAR_UUID @"f19a"
#define LASTNAME_CHAR_UUID @"7a9a"

#define CHECKIN_DATE_CHAR_UUID @"1da7"
#define CHECKOUT_DATE_CHAR_UUID @"0da7"

#define ROOM_NUMBER_CHAR_UUID @"4001"

#define DATE_FORMAT_STRING @"YYYY-MM-dd'T'HH:mm:ss Z"

#endif
