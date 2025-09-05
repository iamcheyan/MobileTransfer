//
//  ViewModel.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import Cocoa
import ColorfulX
import Combine
import DockProgress
import UniformTypeIdentifiers

class ViewModel: ObservableObject {
    static let shared = ViewModel()

    static let defaultBackupLocation = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("MobileTransfer")

    var cancellables: Set<AnyCancellable> = .init()

    enum Page: String {
        case welcome
        case actionMenu
        case findDevice
        case prepareBackup
        case backupProgress
        case prepareRestore
        case restoreProgress
        case installApplication
    }

    @Published var navigationArray: [Page] = [.actionMenu]

    enum Mode {
        case unspecified
        case backup
        case restore
    }

    @Published var mode: Mode = .unspecified

    @Published var deviceIdentifier: String? = nil

    // MARK: - backup

    // sandbox will block our access to these path after reopen
    @Published var backupLocation: String = defaultBackupLocation
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mobiletransfer")
        .path

    @Published var backupApps: Bool = false

    // passed from view
    @Published var backupEncrypted: Bool = false
    @Published var backupApplicationList: [App] = []
    @Published var backupApplicationAccountAllowed: Set<String> = []

    @Published var backupTask: BackupTask?

    // disabled by default due to recent api changes on Apple's server side
    @PublishedStorage(key: "wiki.qaq.showAppPackageDownloadPanel", defaultValue: false)
    var showAppPackageDownloadPanel: Bool

    // MARK: - restore

    enum RestoreMode: String, CaseIterable, Codable {
        case unspecified
        case replace // --system --settings --remove
        case merge // --system --settings --no-reboot
        case mergeWithoutInstallApplication // same as merge
    }

    @Published var restoreLocation: String?
    @Published var restorePassword: String = ""
    @Published var restoreArchiveSystemBuildVersion: String = ""
    @Published var restoreArchiveIsPasswordProtected: Bool = false
    @Published var restoreApplicationsCount: Int = 0
    @Published var restoreMode: RestoreMode = .unspecified

    @Published var restoreTask: RestoreTask?
    @Published var applicationInstallTask: MobileInstallTask?

    // MARK: - Activation

    struct LicenseInfo: Codable, Equatable {
        var licensee: String
        var licenseKey: String
        var validateTo: Date
    }

    @PublishedStorage(key: "LicenseInfo", defaultValue: nil)
    var licenseInfo: LicenseInfo?

    var isLicenseTrail: Bool {
        guard let info = licenseInfo else { return false }
//        return [
//            info.licensee == Mew.trailEmail,
//            info.licenseKey == Mew.trailKey,
//        ].reduce(false) { $0 || $1 }
        return false
    }

    // MARK: - rest of us

    private init() {
        resetAll()
    }

    func resetAll() {
        backupTask?.terminate()
        restoreTask?.terminate()
        applicationInstallTask?.terminate()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        deviceIdentifier = nil
        mode = .unspecified
        backupApps = showAppPackageDownloadPanel
        backupEncrypted = false
        backupApplicationList = []
        backupApplicationAccountAllowed = []
        backupTask = nil
        restoreLocation = nil
        restorePassword = ""
        restoreArchiveIsPasswordProtected = false
        restoreArchiveSystemBuildVersion = ""
        restoreApplicationsCount = 0
        restoreMode = .unspecified
        restoreTask = nil
        applicationInstallTask = nil
        navigationArray = [.actionMenu]

        DispatchQueue.main.async { DockProgress.resetProgress() }
    }
}
