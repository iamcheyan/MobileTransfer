//
//  ViewModel+Computed.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/10/10.
//

import Foundation

extension ViewModel {
    var page: Page {
        get { navigationArray.first ?? .welcome }
        set { navigationArray.insert(newValue, at: 0) }
    }

    var taskCompleted: Bool {
        if let backupTask { return backupTask.completed }
        if let restoreTask { return restoreTask.completed }
        return false
    }

    var taskSuccess: Bool {
        if let backupTask {
            if backupTask.deviceDataTask.error != nil { return false }
            if backupTask.applicationDataTask?.failedTasks.count ?? 0 > 0 { return false }
        }
        if let restoreTask {
            if restoreTask.restoreDeviceTask.error != nil { return false }
        }
        return true
    }

    var overallProgress: Progress {
        let progress = Progress()
        if let backupTask {
            let backupProgress = backupTask.deviceDataTask.overall
            progress.totalUnitCount += backupProgress.totalUnitCount
            progress.completedUnitCount += backupProgress.completedUnitCount
            if let downloadProgress = backupTask.applicationDataTask?.progress {
                progress.totalUnitCount += 100
                progress.completedUnitCount += Int64(100 * downloadProgress)
            }
        }
        if let restoreTask {
            let restoreProgress = restoreTask.restoreDeviceTask.overall
            progress.totalUnitCount += restoreProgress.totalUnitCount
            progress.completedUnitCount += restoreProgress.completedUnitCount
        }
        return progress
    }
}
