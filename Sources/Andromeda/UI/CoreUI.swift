//
//  CoreUI.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

import AppKit
import SwiftUI
import WebKit

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [WKWebView] = []
    @Published var selectedTabIndex: Int = 0
    @Published var tabURLs: [Int: String] = [:]
    @Published var currentURL: String = ""
    @Published var tabTitles: [Int: String] = [:]
    @Published var isFindBarVisible = false
    @Published var searchText = ""
    @Published var tabFavicons: [Int: NSImage] = [:]

    let homePage = "https://andromeda-backend-536388745693.us-central1.run.app/"
    let errorPage = "https://andromeda-backend-536388745693.us-central1.run.app/error.html"

    override init() {
        super.init()
        addNewTab()
    }

    func addNewTab() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []

        let newWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        newWebView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        newWebView.navigationDelegate = self
        newWebView.allowsLinkPreview = true

        tabs.append(newWebView)
        let newIndex = tabs.count - 1
        selectedTabIndex = newIndex
        tabURLs[newIndex] = ""
        tabTitles[newIndex] = "New Tab"

        if let url = URL(string: homePage) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            newWebView.load(request)
            tabURLs[newIndex] = ""
        }
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count, tabs.count > 1 else { return }
        tabs[index].removeFromSuperview()
        tabs.remove(at: index)
        tabURLs.removeValue(forKey: index)
        tabTitles.removeValue(forKey: index)

        selectedTabIndex = min(index, tabs.count - 1)
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
            return WKWebView()
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
            let url = webView.url?.absoluteString ?? ""
            tabURLs[index] = url.contains("andromeda-backend-536388745693.us-central1.run.app") ? "" : url
            tabTitles[index] = webView.title ?? "New Tab"
            
            // Load favicon
            webView.evaluateJavaScript("""
                var link = document.querySelector("link[rel~='icon']");
                link ? link.href : window.location.origin + '/favicon.ico'
            """) { (result, error) in
                if let faviconURLString = result as? String,
                   let faviconURL = URL(string: faviconURLString),
                   let faviconData = try? Data(contentsOf: faviconURL),
                   let favicon = NSImage(data: faviconData) {
                    DispatchQueue.main.async {
                        self.tabFavicons[index] = favicon
                    }
                }
            }
            
            if index == selectedTabIndex {
                currentURL = tabURLs[index] ?? ""
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadErrorPage()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        switch aSelector {
        case #selector(NSText.cut(_:)),
            #selector(NSText.copy(_:)),
            #selector(NSText.paste(_:)),
            #selector(NSText.selectAll(_:)),
            #selector(performFindPanelAction(_:)):
            return true
        default:
            return super.responds(to: aSelector)
        }
    }

    @objc func cut(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.cut(_:)), to: webView, from: self)
    }

    @objc func copy(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.copy(_:)), to: webView, from: self)
    }

    @objc func paste(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.paste(_:)), to: webView, from: self)
    }

    @objc func selectAll(_ sender: Any?) {
        NSApp.sendAction(#selector(NSText.selectAll(_:)), to: webView, from: self)
    }

    @objc func performFindPanelAction(_ sender: Any?) {
        toggleFindBar()
    }

    func toggleFindBar() {
        isFindBarVisible.toggle()
        if isFindBarVisible {
            searchText = ""
            webView.evaluateJavaScript(
                """
                    if (window.getSelection) {
                        window.getSelection().removeAllRanges();
                    }
                """)
        }
    }

    func getDisplayURL(_ url: String) -> String {
        if url.contains("andromeda-backend-536388745693.us-central1.run.app") {
            return ""
        }
        return url
    }
}

struct ContentView: NSViewControllerRepresentable {
    @ObservedObject var viewModel: ViewModel
    let tabIndex: Int

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        viewController.view = NSView(frame: .zero)

        let webView = viewModel.tabs[tabIndex]
        webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
        ])

        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        nsViewController.view.subviews.forEach { $0.removeFromSuperview() }

        let webView = viewModel.tabs[tabIndex]
        webView.translatesAutoresizingMaskIntoConstraints = false
        nsViewController.view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: nsViewController.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: nsViewController.view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: nsViewController.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: nsViewController.view.trailingAnchor),
        ])
    }
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
        NotificationCenter.default.addObserver(
            self, selector: #selector(toggleSidebar), name: NSNotification.Name("ToggleSidebar"),
            object: nil)
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
            HStack(spacing: 0) {
                // Sidebar overlay
                if sidebarManager.isVisible {
                    VStack(spacing: 0) {
                        // Navigation controls in sidebar
                        VStack(spacing: 10) {
                            // URL bar
                            TextField("Enter URL", text: $viewModel.currentURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    viewModel.navigateToURL()
                                }
                                .onChange(of: viewModel.currentURL) { newValue in
                                    viewModel.currentURL = viewModel.getDisplayURL(newValue)
                                }

                            if viewModel.isFindBarVisible {
                                HStack {
                                    TextField("Find in page", text: $viewModel.searchText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: viewModel.searchText) { newValue in
                                            viewModel.webView.evaluateJavaScript(
                                                "window.find('\(newValue)', false, false, true, false, true, false);"
                                            )
                                        }
                                        .frame(height: 24)

                                    Button(action: { viewModel.isFindBarVisible = false }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .padding(.horizontal)
                            }

                            // Navigation buttons
                            HStack(spacing: 15) {
                                Button(action: viewModel.goBack) {
                                    Image(systemName: "chevron.left")
                                }
                                .disabled(!viewModel.webView.canGoBack)

                                Button(action: viewModel.goForward) {
                                    Image(systemName: "chevron.right")
                                }
                                .disabled(!viewModel.webView.canGoForward)

                                Button(action: viewModel.reload) {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }

                            // Tabs
                            ScrollView {
                                VStack(spacing: 5) {
                                    ForEach(0..<viewModel.tabs.count, id: \.self) { index in
                                        tabView(for: index)
                                    }

                                    Button(action: viewModel.addNewTab) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text("New Tab")
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.top, 5)
                                }
                            }
                            .padding(.top)
                        }
                        .padding()
                        .background(VisualEffectView())

                        Spacer()
                    }
                    .frame(width: 250)
                    .background(VisualEffectView())
                    .sidebarHover(isVisible: $sidebarManager.isVisible)
                }

                // Main browser content
                VStack(spacing: 0) {
                    if !viewModel.tabs.isEmpty {
                        ContentView(viewModel: viewModel, tabIndex: viewModel.selectedTabIndex)
                    } else {
                        VisualEffectView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Hover detection area
            if !sidebarManager.isPermanent {
                sidebarTriggerArea(geometry)
            }
        }
    }

    private func tabView(for index: Int) -> some View {
        HStack(spacing: 5) {
            if let favicon = viewModel.tabFavicons[index] {
                Image(nsImage: favicon)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .frame(width: 16, height: 16)
            }
            
            Text(viewModel.tabTitles[index] ?? viewModel.tabURLs[index] ?? "New Tab")
                .lineLimit(1)
                .frame(maxWidth: 150)

            Button(action: { viewModel.closeTab(at: index) }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(viewModel.tabs.count > 1 ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(index == viewModel.selectedTabIndex ? Color.gray.opacity(0.2) : Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .onTapGesture {
            viewModel.selectedTabIndex = index
        }
    }

    private func sidebarTriggerArea(_ geometry: GeometryProxy) -> some View {
        Color.clear
            .frame(width: 5)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering && !sidebarManager.isPermanent {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        sidebarManager.isVisible = true
                    }
                }
            }
            .position(x: 2.5, y: geometry.size.height / 2)
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

    // App Menu
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu
    appMenu.addItem(
        NSMenuItem(
            title: "About Andromeda", action: #selector(AppDelegate.showAboutWindow),
            keyEquivalent: ""))
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(
        NSMenuItem(
            title: "Quit Andromeda", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))

    // Edit Menu
    let editMenuItem = NSMenuItem()
    editMenuItem.title = "Edit"
    mainMenu.addItem(editMenuItem)
    let editMenu = NSMenu(title: "Edit")
    editMenuItem.submenu = editMenu

    editMenu.addItem(
        NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
    editMenu.addItem(
        NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
    editMenu.addItem(
        NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
    editMenu.addItem(
        NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    )
    editMenu.addItem(NSMenuItem.separator())
    editMenu.addItem(
        NSMenuItem(
            title: "Find", action: #selector(ViewModel.performFindPanelAction(_:)),
            keyEquivalent: "f"))

    // View Menu
    let viewMenuItem = NSMenuItem()
    viewMenuItem.title = "View"
    mainMenu.addItem(viewMenuItem)
    let viewMenu = NSMenu(title: "View")
    viewMenuItem.submenu = viewMenu

    viewMenu.addItem(
        NSMenuItem(
            title: "Toggle Sidebar", action: #selector(AppDelegate.toggleSidebar),
            keyEquivalent: "s"))
    viewMenu.addItem(
        NSMenuItem(
            title: "Reload Page", action: #selector(AppDelegate.reloadPage), keyEquivalent: "r"))
}

struct TabContentView: NSViewControllerRepresentable {
    let webView: WKWebView

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        webView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view = webView
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
