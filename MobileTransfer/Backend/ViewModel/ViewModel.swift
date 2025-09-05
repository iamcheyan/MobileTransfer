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
    
    static let copyrightText = "© 2024 砍砍@标准件厂长 版权所有"
    
    // MARK: - Language Settings
    
    @PublishedStorage(key: "SelectedLanguage", defaultValue: "auto")
    var selectedLanguage: String
    
    var currentLanguage: String {
        if selectedLanguage == "auto" {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return selectedLanguage
    }
    
    func setLanguage(_ language: String) {
        selectedLanguage = language
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Language Changed", comment: "")
        alert.informativeText = NSLocalizedString("Please restart the application for the language change to take effect.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Restart Now", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))
        
        if let window = NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    // アプリケーションを再起動
                    let url = Bundle.main.bundleURL
                    let configuration = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                        if error == nil {
                            NSApplication.shared.terminate(nil)
                        }
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }

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
