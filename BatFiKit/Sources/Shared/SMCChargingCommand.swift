//
//  SMCChargingCommand.swift
//  BatFi
//
//  Created by Adam on 16/04/2023.
//

import Foundation

public enum SMCChargingCommand: String, Codable {
    case forceDischarging
    case auto
    case inhibitCharging
    case enableSystemChargeLimit
}
