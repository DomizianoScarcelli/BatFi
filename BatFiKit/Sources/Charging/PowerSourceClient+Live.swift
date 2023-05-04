//
//  PowerSourceClient+Live.swift
//  
//
//  Created by Adam on 02/05/2023.
//

import Dependencies
import Foundation
import IOKit.ps
import os

extension PowerSourceClient: DependencyKey {
    public static var liveValue: PowerSourceClient = {
        let logger = Logger(category: "⚡️")
        func getPowerSourceInfo() -> PowerState {

            let snapshot = IOPSCopyPowerSourcesInfo().takeUnretainedValue()
            let sources = IOPSCopyPowerSourcesList(snapshot).takeUnretainedValue() as Array
            let info = IOPSGetPowerSourceDescription(snapshot, sources[0]).takeUnretainedValue() as! [String: AnyObject]

            let batteryLevel = info[kIOPSCurrentCapacityKey] as? Int
            let isCharging = info[kIOPSIsChargingKey] as? Bool
            let powerSource = info[kIOPSPowerSourceStateKey] as? String
            let timeLeft = info[kIOPSTimeToEmptyKey] as? Int
            let timeToCharge = info[kIOPSTimeToFullChargeKey] as? Int
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
            defer {
                IOServiceClose(service)
                IOObjectRelease(service)
            }
            var cycleClount: Int?
            if let cyclesRef = IORegistryEntryCreateCFProperty(service, kIOPMPSCycleCountKey as CFString, kCFAllocatorDefault, 0) {
                cycleClount = cyclesRef.takeUnretainedValue() as? Int
            }

            var batteryHealth: Int?
            if let healthRef = IORegistryEntryCreateCFProperty(service, kIOPMPSBatteryHealthKey as CFString, kCFAllocatorDefault, 0) {
                batteryHealth = healthRef.takeUnretainedValue() as? Int
            }

            var batteryTemperature: Double?
            if let temperatureRef = IORegistryEntryCreateCFProperty(service, kIOPMPSBatteryTemperatureKey as CFString, kCFAllocatorDefault, 0),
               let temperature = temperatureRef.takeUnretainedValue() as? Double {
                batteryTemperature = temperature / 100
            }

            let powerState = PowerState(
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                powerSource: powerSource,
                timeLeft: timeLeft,
                timeToCharge: timeToCharge,
                batteryCycleCount: cycleClount,
                batteryHealth: batteryHealth,
                batteryTemperature: batteryTemperature
            )
            return powerState
        }
        let observer = Observer()
        let client = PowerSourceClient(
            powerSourceChanges: {
                AsyncStream { continuation in
                    observer.handler = {
                        let powerState = getPowerSourceInfo()
                        logger.debug("New power state: \(powerState, privacy: .public)")
                        continuation.yield(powerState)
                    }
                    continuation.yield(getPowerSourceInfo())
                }
            },
            currentPowerSourceState: getPowerSourceInfo
        )

        return client
    }()

    private class Observer {
        var handler: (() -> Void)?

        init() {
            setUpObserving()
        }

        func setUpObserving() {
            let context = Unmanaged.passUnretained(self).toOpaque()
            let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource(
                {
                    context in
                    if let context {
                        let observer = Unmanaged<Observer>.fromOpaque(context).takeUnretainedValue()
                        observer.updateBatteryState()
                    }
                },
                context
            ).takeRetainedValue() as CFRunLoopSource
            CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.commonModes)
        }

        func updateBatteryState() {
            handler?()
        }
    }
}

extension DependencyValues {
    public var powerSourceClient: PowerSourceClient {
        get { self[PowerSourceClient.self] }
        set { self[PowerSourceClient.self] = newValue }
    }
}
