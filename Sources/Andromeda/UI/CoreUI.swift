//
//  CoreUI.swift
//  Helium
//
//  Created by Tristan Shaw on 10/20/24.
//

import SwiftUI
import WebKit
import AppKit

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [WKWebView] = []
    @Published var selectedTabIndex: Int = 0
    
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
        selectedTabIndex = tabs.count - 1
        loadHomePage(in: newWebView)
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
        webView.reload()
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
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
            webView.load(request)
        } else {
            print("Invalid URL: \(urlString)")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentURL = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadErrorPage()
    }
}

struct ContentView: NSViewControllerRepresentable {
    @ObservedObject var viewModel: ViewModel

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        viewModel.webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view = viewModel.webView
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
            ZStack {
                HSplitView {
                    if sidebarManager.isVisible {
                        sidebarContent
                            .frame(minWidth: 200, idealWidth: 250, maxWidth: .infinity)
                            .transition(.move(edge: .leading))
                            .onHover { hovering in
                                isHovering = hovering
                                if !hovering {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if !isHovering {
                                            withAnimation(.easeIn(duration: 0.3)) {
                                                sidebarManager.isVisible = false
                                            }
                                        }
                                    }
                                }
                            }
                    }

                    ContentView(viewModel: viewModel)
                }
                
                if !sidebarManager.isVisible {
                    Color.clear
                        .frame(width: 10)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHovering = hovering
                            if hovering {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    sidebarManager.isVisible = true
                                }
                            }
                        }
                        .position(x: 5, y: geometry.size.height / 2)
                }
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
        ZStack {
            VisualEffectView()
            
            VStack(spacing: 10) {
                HStack {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "arrow.left")
                    }
                    .disabled(!viewModel.webView.canGoBack)

                    Button(action: { viewModel.goForward() }) {
                        Image(systemName: "arrow.right")
                    }
                    .disabled(!viewModel.webView.canGoForward)

                    Button(action: { viewModel.reload() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding(.horizontal)

                TextField("Enter URL", text: $viewModel.currentURL, onCommit: {
                    viewModel.navigateToURL()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
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
    appMenu.addItem(NSMenuItem(title: "Quit Helium", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
}
