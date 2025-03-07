//
//  ViewModel+Dock.swift
//  MobileTransfer
//
//  Created by 秋星桥 on 2024/10/10.
//

import DockProgress
import Foundation

extension ViewModel {
    func bindProgressToDock() {
        objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                DispatchQueue.main.async { self?.updateProgress() }
            }
            .store(in: &cancellables)
    }

    @MainActor private func updateProgress() {
        if taskCompleted {
            DockProgress.style = .squircle(color: taskSuccess ? .systemGreen : .systemOrange)
            DockProgress.progress = 1
        } else {
            DockProgress.style = .squircle(color: .accent)
            DockProgress.progress = overallProgress.fractionCompleted
        }
    }
}
