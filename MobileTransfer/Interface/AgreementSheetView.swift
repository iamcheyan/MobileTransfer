//
//  AgreementSheetView.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/27.
//

import SwiftUI

struct AgreementSheetView: View {
    @State var text: String = ""

    var body: some View {
        MessageBoxView(title: "Important Message", width: 666) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        let file = Bundle.main.url(forResource: "TermOfService", withExtension: "txt")
                        let textValue = try! String(contentsOf: file!)
                        text = .init(textValue)
                    } label: {
                        Text("Terms of Service")
                            .underline()
                    }
                    .buttonStyle(.plain)
                    Button {
                        let file = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "txt")
                        let textValue = try! String(contentsOf: file!)
                        text = .init(textValue)
                    } label: {
                        Text("Privacy Policy")
                            .underline()
                    }
                    .buttonStyle(.plain)
                    Button {
                        let file = Bundle.main.url(forResource: "License", withExtension: "txt")
                        let textValue = try! String(contentsOf: file!)
                        text = .init(textValue)
                    } label: {
                        Text("Software License")
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                Divider()
                    .padding(.vertical, -16)
                if text.unicodeScalars.isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "flag.and.flag.filled.crossed")
                            .font(.title2)
                            .bold()
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("Please review all the following agreements and policies carefully. You must accept all the agreements and policies to continue using the app.", comment: ""))
                            Text(NSLocalizedString("By continuing to use the app, you agree to the agreements and policies.", comment: ""))
                        }
                    }
                    .frame(maxWidth: 250)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    TextEditor(text: .constant(text))
                        .font(.footnote)
                        .monospaced()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(height: 250)
        }
    }
}
