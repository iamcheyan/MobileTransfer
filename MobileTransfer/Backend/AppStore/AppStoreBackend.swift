//
//  AppStoreBackend.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import ApplePackage
import Foundation

class AppStoreBackend: ObservableObject {
    struct Account: Codable, Identifiable, Equatable, CopyableCodable {
        var id: UUID = .init()

        var email: String
        var password: String
        var countryCode: String
        var storeResponse: StoreResponse.Account
    }

    @PublishedStorage(key: "AppStore.Accounts", defaultValue: [])
    var accounts: [Account]

    static let shared = AppStoreBackend()
    private init() {}

    func save(email: String, password: String, account: StoreResponse.Account) {
        accounts = accounts
            .filter { $0.email.lowercased() != email.lowercased() }
            + [.init(email: email, password: password, countryCode: account.countryCode, storeResponse: account)]
    }

    func delete(id: Account.ID) {
        accounts = accounts.filter { $0.id != id }
    }

    func delete(email: String) {
        accounts = accounts.filter { $0.email != email }
    }

    func updateAllAccountTokens() {
        assert(!Thread.isMainThread)
        let sem = DispatchSemaphore(value: 3)
        let group = DispatchGroup()
        let accounts = accounts
        for account in accounts {
            group.enter()
            DispatchQueue.global().async {
                defer {
                    sem.signal()
                    group.leave()
                }

                let email = account.email
                let password = account.password
                let auth = ApplePackage.Authenticator(email: email)
                guard let account = try? auth.authenticate(password: password, code: "") else { return }

                DispatchQueue.main.asyncAndWait {
                    self.save(email: email, password: password, account: account)
                }
            }
            sem.wait()
        }
        group.wait()
    }
}
