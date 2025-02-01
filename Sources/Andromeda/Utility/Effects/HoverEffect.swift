struct HoverEffect: ViewModifier {
        @State private var isHovered = false

        func body(content: Content) -> some View {
            content
                .foregroundColor(isHovered ? .primary : .gray)
                .opacity(isHovered ? 1 : 0.5)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                    }
                }
        }
    }