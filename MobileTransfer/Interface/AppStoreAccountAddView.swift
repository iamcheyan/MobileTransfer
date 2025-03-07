//
//  AppStoreAccountAddView.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import ApplePackage
import SwiftUI

struct AppStoreAccountAddView: View {
    @StateObject private var backend = AppStoreBackend.shared
    @Environment(\.dismiss) var dismiss

    @State var email: String = ""
    @State var lockEmail: Bool = false

    @State var password: String = ""

    @State var codeRequired: Bool = false
    @State var code: String = ""

    @State var error: Error?
    @State var openProgress: Bool = false

    var completion: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Add Account").font(.headline)
                Spacer()
            }
            Divider()
            sheetBody
            Divider()
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    authenticate()
                } label: {
                    Text("Authenticate")
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350)
        .sheet(isPresented: $openProgress) {
            ProgressPanelView()
        }
        .onAppear {
            lockEmail = !email.isEmpty
        }
    }

    var sheetBody: some View {
        VStack(spacing: 8) {
            TextField("Email (Apple ID)", text: $email)
                .disableAutocorrection(true)
                .disabled(lockEmail)
            SecureField("Password", text: $password)
            if codeRequired {
                TextField("2FA Code (If Needed)", text: $code)
            }
            if let error {
                Text(error.localizedDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
    }

    func authenticate() {
        openProgress = true
        DispatchQueue.global().async {
            defer { DispatchQueue.main.async { openProgress = false } }
            let auth = ApplePackage.Authenticator(email: email)
            do {
                let account = try auth.authenticate(password: password, code: code.isEmpty ? nil : code)
                DispatchQueue.main.async {
                    backend.save(email: email, password: password, account: account)
                    dismiss()
                    completion?(email)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    codeRequired = true
                }
            }
        }
    }
}
