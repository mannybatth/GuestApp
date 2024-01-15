//
//  MotionManager.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/30/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import CoreMotion

import YikesSharedModel

class MotionManager {
    
    static let sharedInstance = MotionManager()
    
    var observers : [Observer] = []
    
    let motionManager = CMMotionManager()
    let updateQueue = OperationQueue()
    
    let intervalForStationary: TimeInterval = 0.5
    let intervalForIsMoving: TimeInterval = 1.0
    
    internal func isStationary () -> Bool {
        if self.motionState == .didBecomeStationary {
            return true
        }
        else {
            return false
        }
    }
    
    var motionState : YKSDeviceMotionState = .isMoving {
        didSet {
            if motionState == .didBecomeStationary {
                #if DEBUG
//                CentralManager.sharedInstance.fireLocalNotification("Device is Stationary!")
                #endif
                self.startAccelerometerUpdatesWithInterval(intervalForStationary)
                self.notifyObservers(ObserverNotification(observableEvent: .DeviceBecameStationary, data: nil))
            } else {
                #if DEBUG
//                CentralManager.sharedInstance.fireLocalNotification("Device is Moving!")
                #endif
                self.startAccelerometerUpdatesWithInterval(intervalForIsMoving)
                
                self.notifyObservers(ObserverNotification(observableEvent: .didBecomeActive, data: nil))
            }
        }
    }
    
    var sameAccelerationCount : Int = 0
    var previousAcceleration : CMAcceleration
    
    let threshold : Double
    
    init() {
        self.updateQueue.maxConcurrentOperationCount = 1;
        // This is the default, but why not specify it (could change...)
        self.updateQueue.qualityOfService = .background
        
        self.previousAcceleration = CMAcceleration(x: 0, y: 0, z: 0);
        self.threshold = EngineConstants.INACTIVITY_SENSITIVITY
        
        self.startAccelerometerUpdatesWithInterval(intervalForIsMoving)
    }
    
    
    func startAccelerometerUpdatesWithInterval(_ interval: Double) {
        
        self.motionManager.accelerometerUpdateInterval = interval;
        
        self.motionManager.stopAccelerometerUpdates()
        self.motionManager.startAccelerometerUpdates(to: self.updateQueue) { (accelerometerData: CMAccelerometerData?, error: Error?) -> Void in
            
            guard let data = accelerometerData
                else { return }
            
            self.handleAcceleration(data, error: error)
        }
        
    }
    
    func handleAcceleration(_ accelerometerData: CMAccelerometerData, error: Error?) {
        
        let diffX : Double = accelerometerData.acceleration.x - self.previousAcceleration.x;
        let diffY : Double = accelerometerData.acceleration.y - self.previousAcceleration.y;
        let diffZ : Double = accelerometerData.acceleration.z - self.previousAcceleration.z;
        
        if (fabs(diffX) > self.threshold || fabs(diffY) > self.threshold || fabs(diffZ) > self.threshold) {
            
            self.sameAccelerationCount = 0;
            if (self.motionState == .didBecomeStationary) {
                self.motionState = .isMoving
            }
            
        } else {
            
            self.sameAccelerationCount += 1;
        }
        
        if (self.sameAccelerationCount > EngineConstants.INACTIVITY_TIMEOUT) {
            if (self.motionState == .isMoving) {
                self.motionState = .didBecomeStationary
            }
        }
        
        self.previousAcceleration = accelerometerData.acceleration;
    }
    
}

extension MotionManager: Observable {
    
    func addObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(_ observer: Observer) {
        let index = observers.index { $0 === observer }
        if index != nil {
            observers.remove(at: index!)
        }
    }
    
    func removeAllObservers() {
        observers = []
    }
    
    func notifyObservers(_ notification: ObserverNotification) {
        for observer in observers {
            observer.notify(notification)
        }
    }
}
