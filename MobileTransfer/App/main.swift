//
//  main.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/24.
//

import Cocoa
import Digger
import Foundation
import SwiftUI

func print(_ items: Any..., separator: String = " ", terminator _: String = "\n") {
    let text = items.map { "\($0)" }.joined(separator: separator)
    NSLog("%@", text)
}

Security.removeDebugger()
guard Security.validateAppSignature() else {
    Security.crashOut()
}

DiggerManager.shared.maxConcurrentTasksCount = 32
DiggerManager.shared.timeout = 60
DiggerCache.cleanDownloadFiles()
DiggerCache.cleanDownloadTempFiles()

NSWindow.allowsAutomaticWindowTabbing = false

MobileTransfer.main()
