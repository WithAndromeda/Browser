import SwiftUI

class SidebarManager: ObservableObject {
    @Published var isVisible = false
    
    func toggle() {
        isVisible.toggle()
    }
}

