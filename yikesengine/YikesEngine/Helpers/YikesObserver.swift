//
//  YikesObserver.swift
//  YikesEngine
//
//  Created by Alexandar Dimitrov on 2016-01-13.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public protocol Observer: class {
    func notify(_ notification: ObserverNotification)
}

public protocol Observable {
        
    func addObserver(_ observer: Observer)
    func removeObserver(_ observer: Observer)
    func notifyObservers(_ notification: ObserverNotification)
}

public struct ObserverNotification {
    var observableEvent: ObservableEvent
    var data: Any?
}

public enum ObservableEvent: String {
    
    // Cases for StoreManager
    case StoreManagerUserWasUpdated
    case StoreManagerStaysAltered
    case StoreManagerStaysRemoved
    
    case YLinksRemoved
    case YLinksAdded
    
    // Cases for MotionManager
    case DeviceBecameStationary
    case didBecomeActive
    
    // Cases for LocationManager
    case LocationStateDidChange
    
    // Cases for ServicesManager
    case MissingServicesDidChange
    
    // Cases for BLEEngine events
    case BLEEngineStartScanning
    case BLEEngineStopScanning
    
    case DiscoveredYLink
    case ConnectingWithYLink
    case FailedToConnectWithYLink
    case ConnectedWithYLink
    case DisconnectedFromYLink
    
    case HandshakeStartedWithYLink
    case HandshakeFailedWithYLink
    case HandshakePassedWithYLink
    
    case ReceivedReportNotificationFromYLink
    case ReceivedTimeSyncNotificationFromYLink
    
    case UnassignedRoom
}

