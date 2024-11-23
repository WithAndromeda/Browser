//
//  SidebarManager.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

#if os(macOS)
import SwiftUI

class SidebarManager: ObservableObject {
    @Published var isVisible = false {
        didSet {
            UserDefaults.standard.set(isVisible, forKey: "sidebarVisible")
        }
    }
    @Published var isPermanent = false {
        didSet {
            UserDefaults.standard.set(isPermanent, forKey: "sidebarPermanent")
        }
    }
    
    init() {
        isVisible = UserDefaults.standard.bool(forKey: "sidebarVisible")
        isPermanent = UserDefaults.standard.bool(forKey: "sidebarPermanent")
    }
    
    func toggle() {
        isVisible.toggle()
        isPermanent = isVisible
    }
    
    func setTemporaryVisibility(_ visible: Bool) {
        if !isPermanent {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = visible
            }
        }
    }
}
#endif