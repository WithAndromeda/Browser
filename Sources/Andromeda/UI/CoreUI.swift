//
//  CoreUI.swift
//  Andromeda
//
//  Created by Tristan Shaw on 10/20/24.
//

import SwiftUI
import WebKit
import AppKit

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [WKWebView] = []
    @Published var selectedTabIndex: Int = 0
    @Published var tabURLs: [Int: String] = [:]
    @Published var currentURL: String = ""
    
    let homePage = "https://helium-api.deno.dev/ui/index.html"
    let errorPage = "https://helium-api.deno.dev/ui/error.html"

    override init() {
        super.init()
        addNewTab()
    }

    func addNewTab() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        let newWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        newWebView.navigationDelegate = self
        newWebView.allowsLinkPreview = true
        
        tabs.append(newWebView)
        let newIndex = tabs.count - 1
        selectedTabIndex = newIndex
        tabURLs[newIndex] = "New Tab"
        
        if let url = URL(string: homePage) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            newWebView.load(request)
            tabURLs[newIndex] = homePage
        }
    }

    func closeTab(at index: Int) {
        guard tabs.count > 1, index >= 0, index < tabs.count else { return }
        tabs.remove(at: index)
        if selectedTabIndex >= tabs.count {
            selectedTabIndex = tabs.count - 1
        }
    }

    func loadHomePage(in webView: WKWebView) {
        if let url = URL(string: homePage) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            webView.load(request)
            currentURL = homePage
        }
    }

    var webView: WKWebView {
        guard !tabs.isEmpty else {
            addNewTab()
            return tabs[0]
        }
        return tabs[selectedTabIndex]
    }

    func loadErrorPage() {
        if let url = URL(string: errorPage) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            webView.load(request)
            currentURL = errorPage
        }
    }

    func reload() {
        tabs[selectedTabIndex].reload()
    }

    func goBack() {
        let currentWebView = tabs[selectedTabIndex]
        if currentWebView.canGoBack {
            currentWebView.goBack()
        }
    }

    func goForward() {
        let currentWebView = tabs[selectedTabIndex]
        if currentWebView.canGoForward {
            currentWebView.goForward()
        }
    }

     func navigateToURL() {
        var urlString = currentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            let currentWebView = tabs[selectedTabIndex]
            currentWebView.load(request)
            tabURLs[selectedTabIndex] = urlString
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let index = tabs.firstIndex(of: webView) {
            tabURLs[index] = webView.url?.absoluteString ?? ""
            if index == selectedTabIndex {
                currentURL = tabURLs[index] ?? ""
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadErrorPage()
    }
}

struct ContentView: NSViewControllerRepresentable {
    @ObservedObject var viewModel: ViewModel
    let tabIndex: Int
    
    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        let webView = viewModel.tabs[tabIndex]
        webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view = webView
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

struct WindowControlButton: View {
    let systemName: String
    let action: () -> Void
    let color: Color

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class SidebarVisibilityManager: ObservableObject {
    @Published var isVisible = true
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(toggleSidebar), name: NSNotification.Name("ToggleSidebar"), object: nil)
    }
    
    @objc func toggleSidebar() {
        isVisible.toggle()
    }
}

struct BrowserView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var sidebarManager: SidebarManager
    @State private var isHovering = false

    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                if sidebarManager.isVisible {
                    sidebarContent
                        .frame(width: 200)
                        .transition(.move(edge: .leading))
                        .onHover { hovering in
                            handleHover(hovering)
                        }
                }
                
                VStack(spacing: 0) {
                    // Tab bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(0..<viewModel.tabs.count, id: \.self) { index in
                                tabView(for: index)
                            }
                            
                            Button(action: { viewModel.addNewTab() }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(height: 35)
                    .background(VisualEffectView())
                    
                    TabContentView(webView: viewModel.tabs[viewModel.selectedTabIndex])
                        .id(viewModel.selectedTabIndex)
                }
            }
            
            if !sidebarManager.isVisible {
                sidebarTriggerArea(geometry)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { sidebarManager.toggle() }) {
                    Image(systemName: sidebarManager.isVisible ? "sidebar.left" : "sidebar.right")
                }
            }
        }
        .navigationTitle("")
        .frame(minWidth: 800, minHeight: 600)
        .animation(.easeInOut(duration: 0.3), value: sidebarManager.isVisible)
    }
    
    private var sidebarContent: some View {
        VStack {
            HStack(spacing: 10) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.tabs[viewModel.selectedTabIndex].canGoBack)
                
                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.tabs[viewModel.selectedTabIndex].canGoForward)
                
                Button(action: { viewModel.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()
            
            TextField("Enter URL", text: $viewModel.currentURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onSubmit {
                    viewModel.navigateToURL()
                }
            
            Spacer()
        }
        .background(VisualEffectView())
    }
    
    private func tabView(for index: Int) -> some View {
        HStack(spacing: 8) {
            Text(viewModel.tabURLs[index]?.components(separatedBy: "/").last ?? "New Tab")
                .lineLimit(1)
                .frame(maxWidth: 150)
            
            if viewModel.tabs.count > 1 {
                Button(action: { viewModel.closeTab(at: index) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(viewModel.selectedTabIndex == index ? Color.gray.opacity(0.2) : Color.clear)
        .onTapGesture {
            viewModel.selectedTabIndex = index
        }
    }
    
    private func handleHover(_ hovering: Bool) {
        isHovering = hovering
        if !hovering && !sidebarManager.isPermanent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !isHovering {
                    withAnimation(.easeIn(duration: 0.3)) {
                        sidebarManager.isVisible = false
                    }
                }
            }
        }
    }
    
    private func sidebarTriggerArea(_ geometry: GeometryProxy) -> some View {
        Color.clear
            .frame(width: 10)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering && !sidebarManager.isPermanent {
                    withAnimation(.easeOut(duration: 0.3)) {
                        sidebarManager.isVisible = true
                    }
                }
            }
            .position(x: 5, y: geometry.size.height / 2)
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .sidebar
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

func setupMenu() {
    let mainMenu = NSMenu()
    NSApp.mainMenu = mainMenu

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu
    appMenu.addItem(NSMenuItem(title: "Quit Andromeda", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
}

struct TabContentView: NSViewControllerRepresentable {
    let webView: WKWebView
    
    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view = webView
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        let webView = self.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        nsViewController.view = webView
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: nsViewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: nsViewController.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: nsViewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: nsViewController.view.trailingAnchor)
        ])
    }
}
