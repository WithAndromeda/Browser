import SwiftUI
import WebKit

struct HistoryItemView: View {
    let item: HistoryItem
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        HStack {
            if let faviconData = item.faviconData,
               let favicon = NSImage(data: faviconData) {
                Image(nsImage: favicon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .fontWeight(.medium)
                Text(item.url)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(item.date.formatted())
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .gesture(
            TapGesture(count: 2).onEnded(onDoubleTap)
        )
        .onTapGesture(perform: onTap)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var viewModel: ViewModel
    @State private var selectedItemId: UUID?
    
    var body: some View {
        VStack {
            Text("Browser History")
                .font(.title)
                .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.history.enumerated().reversed()), id: \.element.id) { _, item in
                        HistoryItemView(
                            item: item,
                            isSelected: selectedItemId == item.id,
                            onTap: {
                                selectedItemId = item.id
                            },
                            onDoubleTap: {
                                if let url = URL(string: item.url) {
                                    viewModel.currentURL = url.absoluteString
                                    viewModel.navigateToURL()
                                    NSApplication.shared.windows.first { $0.title == "Browser History" }?.close()
                                }
                            }
                        )
                        Divider()
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
} 