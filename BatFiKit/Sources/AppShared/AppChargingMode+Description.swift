//
//  AppChargingState.Mode+.swift
//
//
//  Created by Adam on 15/05/2023.
//

import Foundation
import L10n

public extension AppChargingMode {
    var stateDescription: String {
        let label = L10n.AppChargingMode.State.Title.self

        guard mode != .initial else {
            return label.initial
        }

        guard chargerConnected || mode == .forceDischarge else {
            return label.chargerNotConnected
        }

        if userTempOverride != nil {
            return label.chargeOverride
        }

        switch self.mode {
        case .initial:
            return label.initial
        case .charging:
            return label.charging
        case .forceDischarge:
            return label.forceDischarge
        case .inhibit:
            return label.inhibit
        }
    }

    func stateDescription(chargeLimitFraction limit: Double) -> String? {
        let limit = percentageFormatter.string(from: limit as NSNumber)!
        let label = L10n.AppChargingMode.State.Description.self

        guard chargerConnected || mode == .forceDischarge else {
            return nil
        }

        if let overrideLimit = userTempOverride?.limit {
            let limitFraction = Double(overrideLimit) / 100
            let percentage = percentageFormatter.string(from: NSNumber(floatLiteral: limitFraction))!
            return label.tempChargingTo(percentage)
        }

        switch self.mode {
        case .initial:
            return nil
        case .charging:
            return label.charging(limit)
        case .forceDischarge:
            return label.forceDischarge
        case .inhibit:
            return label.inhibit(limit)
        }
    }
}
