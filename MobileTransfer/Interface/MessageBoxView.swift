//
//  MessageBoxView.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import SwiftUI

struct MessageBoxView<Content: View>: View {
    let title: LocalizedStringKey
    let width: CGFloat
    let spacing: CGFloat
    let content: Content

    init(title: LocalizedStringKey = "Message", width: CGFloat = 450, spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.title = title
        self.width = width
        self.spacing = spacing
        self.content = content()
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text(title).bold()
                Spacer()
            }
            .padding(spacing)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                content.frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(spacing)
            Divider()
            HStack {
                Spacer()
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(spacing)
        }
        .frame(width: width)
    }
}
