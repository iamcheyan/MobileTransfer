//
//  HoverPopModifier.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/9/25.
//

import SwiftUI

struct HoverPopModifier: ViewModifier {
    @State var hover: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(hover ? 1.025 : 1)
            .onHover { hover = $0 }
            .animation(.spring, value: hover)
    }
}
