//
//  SidebarManager.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

import SwiftUI

class SidebarManager: ObservableObject {
    @Published var isVisible = false
    @Published var isPermanent = false
    
    func toggle() {
        isVisible.toggle()
        isPermanent = isVisible
    }
}

