//
//  RestoreTaskView.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/26.
//

import SwiftUI

struct RestoreTaskView: View {
    @StateObject var task: RestoreTask

    @ViewBuilder
    var body: some View {
        RestoreDeviceDataTaskView(task: task.restoreDeviceTask)
    }
}
