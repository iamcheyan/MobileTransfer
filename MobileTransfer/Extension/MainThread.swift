//
//  MainThread.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/10/23.
//

import Foundation

func requiresMainThread(_ exec: @escaping () -> Void) {
    if Thread.isMainThread { exec() }
    else { DispatchQueue.main.asyncAndWait { exec() } }
}
