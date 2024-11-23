//
//  SidebarHoverModifier.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

import SwiftUI

struct SidebarHoverModifier: ViewModifier {
    @Binding var isVisible: Bool
    @State private var isHovering = false
    @EnvironmentObject var sidebarManager: SidebarManager
    
    func body(content: Content) -> some View {
        content
            .frame(width: 250)
            .offset(x: isVisible ? 0 : -250)
            .zIndex(1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
            .onHover { hovering in
                isHovering = hovering
                if !isVisible && hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if isHovering {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isVisible = true
                            }
                        }
                    }
                } else if isVisible && !hovering && !sidebarManager.isPermanent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !isHovering {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isVisible = false
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

