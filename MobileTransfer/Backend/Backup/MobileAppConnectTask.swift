//
//  MobileAppConnectTask.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import ApplePackage
import Combine
import Digger
import Foundation

private let httpClient = HTTPClient(urlSession: URLSession.shared)
private let itunesClient = iTunesClient(httpClient: httpClient)
private let storeClient = StoreClient(httpClient: httpClient)

class MobileAppConnectTask: ObservableObject, Identifiable {
    let id: UUID = .init()

    let appList: [App]
    let allowedAccounts: Set<String>
    let storeBase: URL

    var cancelled = false
    var cancellables: Set<AnyCancellable> = []

    @Published var runningTasks: [DownloadTask] = []
    @Published var successTasks: [DownloadTask] = []
    @Published var failedTasks: [DownloadTask] = []
    @Published var logs: [String] = []

    var progress: Double {
        guard !appList.isEmpty else { return 0 }
        return Double(successTasks.count + failedTasks.count) / Double(appList.count)
    }

    var completed: Bool {
        appList.isEmpty || successTasks.count + failedTasks.count == appList.count
    }

    var success: Bool {
        appList.isEmpty || successTasks.count == appList.count
    }

    init(appList: [App], allowedAccounts: Set<String>, storeBase: URL) {
        self.appList = appList
        self.allowedAccounts = Set(allowedAccounts.map { $0.lowercased() })
        self.storeBase = storeBase

        try? FileManager.default.createDirectory(
            at: storeBase,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    func dispatchOutput(_ text: String) {
        if Thread.isMainThread {
            logs.append(text)
        } else {
            DispatchQueue.main.asyncAndWait {
                self.logs.append(text)
            }
        }
    }

    func start() {
        assert(!Thread.isMainThread)

        dispatchOutput(NSLocalizedString("Downloading packages...", comment: ""))

        let sem = DispatchSemaphore(value: 5)
        let group = DispatchGroup()
        for item in appList {
            group.enter()
            sem.wait()
            DispatchQueue.global().async {
                autoreleasepool {
                    defer {
                        sem.signal()
                        group.leave()
                    }
                    // must process so we keep assert working
                    self.process(item)
                }
            }
        }
        group.wait()

        assert(runningTasks.isEmpty)
        assert(successTasks.count + failedTasks.count == appList.count)

        dispatchOutput(NSLocalizedString("Task Completed", comment: ""))
    }

    func terminate() {
        cancelled = true
        DiggerManager.shared.cancelAllTasks()
        DiggerCache.cleanDownloadFiles()
        DiggerCache.cleanDownloadTempFiles()
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    private func prepare(_ app: App) -> (AppStoreBackend.Account, iTunesResponse.iTunesArchive, StoreResponse.Account, StoreResponse.Item)? {
        let account = app.account
        if account == "*" {
            let accounts = AppStoreBackend.shared.accounts.filter {
                allowedAccounts.contains($0.email.lowercased())
            }
            for account in accounts {
                if let (archiveItem, item) = retrieveStoreItems(
                    bundleIdentifier: app.bundleIdentifier,
                    account: account
                ) {
                    return (account, archiveItem, account.storeResponse, item)
                }
            }
            return nil
        } else {
            let account = AppStoreBackend.shared.accounts.first {
                $0.email.lowercased() == app.account.lowercased()
            }
            guard let account else { return nil }
            guard let (archiveItem, item) = retrieveStoreItems(
                bundleIdentifier: app.bundleIdentifier,
                account: account
            ) else { return nil }
            return (account, archiveItem, account.storeResponse, item)
        }
    }

    private func retrieveStoreItems(
        bundleIdentifier: String,
        account: AppStoreBackend.Account
    ) -> (iTunesResponse.iTunesArchive, StoreResponse.Item)? {
        for _ in 0 ..< 3 where !cancelled {
            for type in EntityType.allCases {
                guard let archiveItem = try? itunesClient.lookup(
                    type: type,
                    bundleIdentifier: bundleIdentifier,
                    region: account.countryCode
                ), let item = try? storeClient.item(
                    identifier: String(archiveItem.identifier),
                    directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier
                )
                else { continue }
                return (archiveItem, item)
            }
        }
        return nil
    }

    private func process(_ app: App) {
        assert(!Thread.isMainThread)

        let task = DownloadTask()
        task.appName = app.name
        task.appVersion = "0"

        defer {
            DispatchQueue.main.asyncAndWait {
                self.runningTasks.removeAll { $0.id == task.id }
                if task.error != nil {
                    self.failedTasks.append(task)
                } else {
                    self.successTasks.append(task)
                }
            }
        }

        DispatchQueue.main.asyncAndWait {
            task.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }

        guard !cancelled else {
            DispatchQueue.main.asyncAndWait {
                task.error = NSLocalizedString("Cancelled", comment: "")
            }
            return
        }

        let prepareResult = prepare(app)
        guard let prepareResult else {
            DispatchQueue.main.asyncAndWait {
                task.error = NSLocalizedString("Failed to fetch app info", comment: "")
            }
            return
        }

        guard !cancelled else {
            DispatchQueue.main.asyncAndWait {
                task.error = NSLocalizedString("Cancelled", comment: "")
            }
            return
        }

        task.appAvatar = prepareResult.1.artworkUrl512 ?? ""
        task.appName = prepareResult.1.name
        task.appVersion = prepareResult.1.version
        task.appURL = prepareResult.3.url

        DispatchQueue.main.asyncAndWait { self.runningTasks.append(task) }

        let name = "\(app.bundleIdentifier)+\(prepareResult.3.md5).ipa"
        let targetFile = storeBase.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: targetFile.path) {
            DispatchQueue.main.asyncAndWait { task.error = nil }
            return
        }

        (
            try? FileManager.default.contentsOfDirectory(atPath: storeBase.path)
        )?
            .filter { $0.hasPrefix(app.bundleIdentifier + "+") }
            .forEach {
                print("[+] removing old file: \(storeBase.appendingPathComponent($0).path)")
                try? FileManager.default.removeItem(at: storeBase.appendingPathComponent($0))
            }

        var tempUrl: URL? = nil
        var lastError: Error?

        var downloadRetryLimiter = 8
        while downloadRetryLimiter > 0, tempUrl == nil, !cancelled {
            downloadRetryLimiter -= 1

            var someProgressHasBeenMade = false
            var wasTerminatedDueToLowSpeed = false
            defer {
                if someProgressHasBeenMade || wasTerminatedDueToLowSpeed {
                    downloadRetryLimiter += 1
                }
            }

            let lowSpeedBarrier = 5 * 1024 // 5KB
            let lowSpeedBarrierEnabler = 500 * 1024 // if met 500KB download speed, then reset low speed counter
            let lowSpeedTerminator = 8 // for over 8 times report low speed, then terminate
            var lowSpeedTerminatorCount = -1 // to ignore the first report
            var lowSpeedTerminatorEnabled = false
            var speedUpdatedAt: Date = .init()

            let sem = DispatchSemaphore(value: 0)
            let diggerURL = prepareResult.3.url
            DiggerManager.shared.download(with: diggerURL)
                .progress { progress in
                    task.progress = progress.fractionCompleted
                }
                .speed { speedBytes in
                    defer { speedUpdatedAt = Date() }

                    // drop first report due to cache read
                    if lowSpeedTerminatorCount == -1 {
                        lowSpeedTerminatorCount = 0
                        return
                    }

                    // now update the speed and enable the counter
                    task.speed = Int(speedBytes)
                    if speedBytes > 0 { someProgressHasBeenMade = true }

                    // for low speed terminator
                    if speedBytes > lowSpeedBarrierEnabler { lowSpeedTerminatorEnabled = true }
                    if speedBytes < lowSpeedBarrier, lowSpeedTerminatorEnabled {
                        lowSpeedTerminatorCount += 1
                    } else {
                        lowSpeedTerminatorCount = 0
                    }

                    if lowSpeedTerminatorCount > lowSpeedTerminator ||
                        // 如果下载速度缓慢的话可能会很长时间不更新速度 所以如果超过 10 秒没更新 并且速度在低速范围内 就认为是低速
                        (speedUpdatedAt.timeIntervalSinceNow < -10 && speedBytes < lowSpeedBarrier)
                    {
                        self.dispatchOutput(NSLocalizedString("Download speed is slow, retrying...", comment: ""))
                        wasTerminatedDueToLowSpeed = true
                        DiggerManager.shared.cancelTask(for: diggerURL)
                    }
                }
                .completion { result in
                    switch result {
                    case let .success(url):
                        let newTemp = URL(fileURLWithPath: NSTemporaryDirectory())
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("ipa")
                        try? FileManager.default.createDirectory(
                            at: newTemp.deletingLastPathComponent(),
                            withIntermediateDirectories: true
                        )
                        try? FileManager.default.moveItem(at: url, to: newTemp)
                        tempUrl = newTemp
                    case let .failure(error):
                        lastError = error
                    }
                    sem.signal()
                }
            sem.wait()
            sleep(1)
        }

        guard let tempUrl else {
            DispatchQueue.main.asyncAndWait {
                task.error = lastError?.localizedDescription
            }
            return
        }

        let md5 = prepareResult.3.md5
        let fileMD5 = md5File(url: tempUrl)
        guard md5.lowercased() == fileMD5?.lowercased() else {
            DispatchQueue.main.asyncAndWait {
                task.error = NSLocalizedString("File hash mismatch", comment: "")
            }
            return
        }

        do {
            let signatureClient = SignatureClient(fileManager: .default, filePath: tempUrl.path)
            try signatureClient.appendMetadata(item: prepareResult.3, email: prepareResult.0.email)
            try signatureClient.appendSignature(item: prepareResult.3)

            try? FileManager.default.removeItem(at: targetFile)
            try? FileManager.default.createDirectory(
                at: targetFile.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.moveItem(at: tempUrl, to: targetFile)

            DispatchQueue.main.asyncAndWait {
                task.error = nil
            }
        } catch {
            DispatchQueue.main.asyncAndWait {
                task.error = error.localizedDescription
            }
        }
    }
}

private let byteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
    return formatter
}()

extension MobileAppConnectTask {
    class DownloadTask: Identifiable, ObservableObject, Equatable {
        static func == (lhs: MobileAppConnectTask.DownloadTask, rhs: MobileAppConnectTask.DownloadTask) -> Bool {
            lhs.id == rhs.id &&
                lhs.appAvatar == rhs.appAvatar &&
                lhs.appName == rhs.appName &&
                lhs.appVersion == rhs.appVersion &&
                lhs.appURL == rhs.appURL &&
                lhs.progress == rhs.progress &&
                lhs.speed == rhs.speed &&
                lhs.error == rhs.error &&
                true
        }

        var id: UUID = .init()

        @Published var appAvatar: String = ""
        @Published var appName: String = ""
        @Published var appVersion: String = ""
        @Published var appURL: URL = .init(fileURLWithPath: UUID().uuidString)

        @Published var progress: Double = 0
        @Published var speed: Int = 0
        @Published var error: String? = nil

        var progressText: String {
            "\(Int(progress * 100))%"
        }

        var speedText: String {
            if speed > 0 { return byteFormatter.string(fromByteCount: Int64(speed)) + "/s" }
            return ""
        }

        init() {}
    }
}
