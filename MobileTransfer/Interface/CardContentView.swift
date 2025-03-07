//
//  CardContentView.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import SwiftUI

struct CardContentView<V: View>: View {
    @ViewBuilder
    let content: V

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CardContentHeader<V: View>: View {
    let icon: String
    let title: LocalizedStringKey

    @ViewBuilder
    let trailingView: V

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
                .bold()
            Spacer()
            trailingView
                .transition(.opacity.combined(with: .scale))
        }
    }
}
