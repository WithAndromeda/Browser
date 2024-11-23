//
//  SidebarHoverModifier.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

#if os(macOS)
import SwiftUI

struct SidebarHoverModifier: ViewModifier {
    @Binding var isVisible: Bool
    @State private var isHovering = false
    @EnvironmentObject var sidebarManager: SidebarManager
    
    func body(content: Content) -> some View {
        let response = 0.3
        let damping = 1.0
        
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                .frame(width: 250)
                .offset(x: isVisible ? 0 : -250)
                .animation(.spring(response: response, dampingFraction: damping), value: isVisible)
            
            content
                .frame(width: 250)
                .offset(x: isVisible ? 0 : -250)
                .zIndex(1)
                .animation(.spring(response: response, dampingFraction: damping), value: isVisible)
        }
        .onHover { hovering in
            isHovering = hovering
            if !sidebarManager.isPermanent {
                if hovering {
                    withAnimation(.spring(response: response, dampingFraction: damping)) {
                        sidebarManager.setTemporaryVisibility(true)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !isHovering {
                            withAnimation(.spring(response: response, dampingFraction: damping)) {
                                sidebarManager.setTemporaryVisibility(false)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func sidebarHover(isVisible: Binding<Bool>) -> some View {
        modifier(SidebarHoverModifier(isVisible: isVisible))
    }
}
#endif

