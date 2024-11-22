import SwiftUI

struct SidebarHoverModifier: ViewModifier {
    @Binding var isVisible: Bool
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isVisible && value.location.x < 10 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isVisible = true
                            }
                        }
                    }
            )
            .onHover { hovering in
                isHovering = hovering
                if !isVisible && hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if isHovering {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isVisible = true
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    func sidebarHover(isVisible: Binding<Bool>) -> some View {
        self.modifier(SidebarHoverModifier(isVisible: isVisible))
    }
}

