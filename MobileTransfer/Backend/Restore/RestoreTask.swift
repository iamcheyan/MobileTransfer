//
//  RestoreTask.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/26.
//

import Combine
import Foundation

class RestoreTask: Identifiable, ObservableObject {
    let id: UUID = .init()

    struct RestoreTaskParameter: Codable {
        let udid: String
        let mode: ViewModel.RestoreMode
        let archiveLocation: URL
        let archivePassword: String
    }

    let parameter: RestoreTaskParameter

    var cancellable: Set<AnyCancellable> = []

    var completed: Bool {
        if !restoreDeviceTask.completed { return false }
        return true
    }

    var success: Bool {
        if !restoreDeviceTask.success { return false }
        return true
    }

    let restoreDeviceTask: MobileRestoreTask

    init(parameter: RestoreTaskParameter) {
        self.parameter = parameter

        restoreDeviceTask = .init(config: .init(
            id: .init(),
            device: .init(
                udid: parameter.udid,
                deviceRecord: .init(),
                pairRecord: .init(),
                extra: [:],
                possibleNetworkAddress: []
            ),
            useNetwork: false,
            useStoreBase: parameter.archiveLocation,
            password: parameter.archivePassword,
            parameters: parameter.mode.commandLineParameters
        ))

        restoreDeviceTask.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if self?.completed ?? false {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellable)
    }

    deinit {
        terminate()
    }

    func run() {
        assert(!Thread.isMainThread)
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global(qos: .utility).async {
            self.restoreDeviceTask.start()
            group.leave()
        }

        group.wait()
        assert(completed)
    }

    func terminate() {
        restoreDeviceTask.terminate()
    }
}

extension ViewModel.RestoreMode {
    var commandLineParameters: [String] {
        switch self {
        case .unspecified:
            assertionFailure()
            return []
        case .replace:
            return ["--system", "--settings", "--remove"]
        case .merge, .mergeWithoutInstallApplication:
            return ["--system", "--settings"]
        }
    }
}
