//
//  MobileRestoreTask.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/26.
//

import AppleMobileDeviceLibrary
import AuxiliaryExecute
import Combine
import Foundation

private let dateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    formatter.locale = .init(identifier: "en_US_POSIX")
    return formatter
}()

private let ignoredKeywords = [
    "Receiving files",
]

class MobileRestoreTask: ObservableObject, Identifiable {
    var id: UUID = .init()
    let date: Date = .init()

    struct Configuration: Codable, CopyableCodable {
        let id: UUID
        let device: Device
        let useNetwork: Bool
        let useStoreBase: URL
        let password: String
        let parameters: [String]
    }

    let config: Configuration
    var cancellable: Set<AnyCancellable> = []
    init(config: Configuration) {
        self.config = config.codableCopy()!
        throttledSubject
            .throttle(for: .seconds(0.2), scheduler: DispatchQueue.global(), latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellable)
    }

    struct Log: Identifiable {
        var id: UUID = .init()
        let date: Date = .init()
        let text: String
    }

    var output: [Log] = [] {
        didSet { throttledSubject.send() }
    }

    let throttledSubject = PassthroughSubject<Void, Never>()

    var overall: Progress = .init() {
        didSet {
            guard current != oldValue else { return }
            throttledSubject.send()
        }
    }

    var current: Progress = .init() {
        didSet {
            guard current != oldValue else { return }
            throttledSubject.send()
        }
    }

    private let currentSubject = PassthroughSubject<Progress, Never>()

    enum RestoreError: Error {
        case unknown
        case deviceNotFound
        case interrupted
        case unexpectedExitCode
        case terminated
    }

    @Published var error: RestoreError? = nil

    enum RestoreStatus {
        case initialized
        case executing
        case completed
    }

    @Published var status: RestoreStatus = .initialized
    var executing: Bool { status == .executing || pid != nil }
    var completed: Bool { [.completed].contains(status) }
    var success: Bool { error == nil }

    @Published var pid: pid_t? = nil
    @Published var recp: AuxiliaryExecute.ExecuteReceipt? = nil

    func start() {
        guard status == .initialized else { return }
        status = .executing
        executeStart()
    }

    func terminate() {
        requiresMainThread { self.error = .terminated }
        defer { decodeOutput("Terminated by request.\n") }
        guard let pid else { return }
        kill(pid, SIGKILL)
    }

    private func executeStart() {
        assert(!Thread.isMainThread)

        overall.totalUnitCount = 100
        current.totalUnitCount = 100

        let args = config.decodeBinaryCommand()
        decodeOutput("\(Self.mobileBackupExecutable)\n")
        decodeOutput("Core Version: \(Self.mobileBackupVersion)\n")
        decodeOutput("Core Command: \(args)\n")

        defer {
            sleep(1)
            decodeOutput("\n\n\n")
            requiresMainThread {
                self.pid = nil
                if self.overall.completedUnitCount != self.overall.totalUnitCount {
                    self.overall.totalUnitCount = 100
                    self.overall.completedUnitCount = 100
                }
                self.status = .completed
            }
        }

        let link = config.useStoreBase.appendingPathComponent(config.id.uuidString)
        let target = config.useStoreBase
        do {
            if FileManager.default.fileExists(atPath: link.path) {
                try FileManager.default.removeItem(at: link)
            }
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        } catch {
            decodeOutput("failed to create link: \(error)\n")
            DispatchQueue.main.asyncAndWait {
                self.error = .unknown
            }
            return
        }
        defer {
            try? FileManager.default.removeItem(at: link)
        }

        decodeOutput("starting command...\n")
        let recp = AuxiliaryExecute.spawn(
            command: Self.mobileBackupExecutable,
            args: args,
            environment: [:],
            timeout: -1
        ) { pid in
            requiresMainThread { self.pid = pid }
        } output: { output in
            self.decodeOutput(output)
        }
        decodeOutput("\n\n\n")
        decodeOutput("result: \(recp.exitCode)\n")

        requiresMainThread { self.decodeReceipt(recp) }
    }

    // MARK: OUTPUT HANDLER

    private func decodeReceipt(_ recp: AuxiliaryExecute.ExecuteReceipt) {
        overall.totalUnitCount = 100
        overall.completedUnitCount = 100
        self.recp = recp
        status = .completed
        if recp.exitCode != 0, error == nil {
            error = .unexpectedExitCode
        }
    }

    private var buffer = ""
    private func decodeOutput(_ output: String) {
        buffer += output
        buffer = buffer.replacingOccurrences(of: "\r", with: "\n")
        guard buffer.contains("\n") else { return }
        var lineBuffer = ""
        let copyBuffer = buffer
        buffer = ""
        for char in copyBuffer {
            if char == "\n" || char == "\r" {
                decodeLine(lineBuffer)
                lineBuffer = ""
            } else {
                lineBuffer.append(char)
            }
        }
        if !lineBuffer.isEmpty { buffer = lineBuffer }
    }

    private func decodeLine(_ input: String) {
        let line = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }

        // overall progress found
        if line.hasPrefix("["), line.contains("]"), line.hasSuffix("Finished") {
            guard let cutA = line.components(separatedBy: "]").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let cutB = cutA.components(separatedBy: "%").first,
                  let value = Int(cutB),
                  value >= 0, value <= 100
            else { return }
            let prog = Progress(totalUnitCount: 100)
            prog.completedUnitCount = Int64(value)
            guard overall != prog else { return }
            requiresMainThread { self.overall = prog }
            return
        }

        // partial progress found
        if line.hasPrefix("["), line.contains("]"), line.contains("("), line.contains(")"), line.contains("/") {
            guard let cutA = line.components(separatedBy: "(").last,
                  let currentValue = cutA.components(separatedBy: "/").first,
                  let cutB = line.components(separatedBy: ")").first,
                  let totalValue = cutB.components(separatedBy: "/").last,
                  let curr = SizeDecoder.decode(currentValue),
                  let total = SizeDecoder.decode(totalValue)
            else { return }
            let prog = Progress(totalUnitCount: Int64(total))
            prog.completedUnitCount = Int64(curr)
            guard current != prog else { return }
            requiresMainThread { self.current = prog }
            return
        }

        for keyword in ignoredKeywords where line.contains(keyword) {
            return
        }

        guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        NSLog("[BackupTask] \(id) \(line)")
        requiresMainThread { self.output.append(.init(text: line)) }
    }
}

extension MobileRestoreTask {
    static let mobileBackupExecutable = Bundle.main.url(forAuxiliaryExecutable: "MobileBackup")!.path
    static let mobileBackupVersion: String = {
        var stdout = AuxiliaryExecute.spawn(
            command: mobileBackupExecutable,
            args: ["-v"]
        ).stdout
        if stdout.hasPrefix("idevicebackup2") {
            stdout.removeFirst("idevicebackup2".count)
        }
        stdout = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return stdout
    }()
}

extension MobileRestoreTask.Configuration {
    func decodeBinaryCommand() -> [String] {
        var ans = [String]()
        ans += ["-u", device.udid]
        ans += ["--source", id.uuidString]
        if useNetwork { ans += ["-n"] }
        ans += ["restore"]
        if !password.isEmpty { ans += ["--password", password] }
        ans += parameters
        ans += [useStoreBase.path]
        return ans
    }
}
