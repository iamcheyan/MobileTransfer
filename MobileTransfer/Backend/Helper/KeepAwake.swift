//
//  KeepAwake.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/10/3.
//

import Foundation
import IOKit.pwr_mgt

enum KeepAwake {
    private static var assertionID: IOPMAssertionID = 0
    private static var success: IOReturn?

    @discardableResult
    static func enableSleep() -> Bool {
        if success != nil {
            success = IOPMAssertionRelease(assertionID)
            success = nil
            return true
        }
        return false
    }

    @discardableResult
    static func disableSleep() -> Bool? {
        guard success == nil else { return nil }
        success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            Bundle.main.bundleIdentifier! as CFString,
            &assertionID
        )
        return success == kIOReturnSuccess
    }
}
