//
//  ProgressPanelView.swift
//  BBackupp
//
//  Created by 秋星桥 on 2024/3/15.
//

import SwiftUI

struct ProgressPanelView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .frame(width: 300, height: 200, alignment: .center)
    }
}
