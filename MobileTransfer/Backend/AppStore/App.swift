//
//  App.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import Foundation

struct App: Codable {
    let bundleIdentifier: String
    let name: String
    let account: String

    init(bundleIdentifier: String, name: String = "", account: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.account = account
    }
}
