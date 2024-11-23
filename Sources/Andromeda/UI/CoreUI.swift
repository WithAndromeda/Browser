//
//  CoreUI.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

import AppKit
import SwiftUI
import WebKit

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let date: Date
    let faviconData: Data?
}

struct TabState: Codable {
    let url: String
    let title: String
}

class ViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var tabs: [WKWebView] = []
    @Published var selectedTabIndex: Int = 0
    @Published var tabURLs: [Int: String] = [:]
    @Published var currentURL: String = ""
    @Published var tabTitles: [Int: String] = [:]
    @Published var isFindBarVisible = false
    @Published var searchText = ""
    @Published var tabFavicons: [Int: NSImage] = [:]
    @Published var history: [HistoryItem] = []

    let homePage = "https://andromeda-backend-536388745693.us-central1.run.app/"
    let errorPage = "https://andromeda-backend-536388745693.us-central1.run.app/error.html"

    private let tabsKey = "savedTabs"
    public let settingsManager = SettingsManager()

    override init() {
        super.init()
        loadSavedTabs()
    }

    private func loadSavedTabs() {
        if let data = UserDefaults.standard.data(forKey: tabsKey),
           let savedTabs = try? JSONDecoder().decode([TabState].self, from: data) {
            if !savedTabs.isEmpty {
                tabs.removeAll()
                for tab in savedTabs {
                    addNewTab(withURL: tab.url, title: tab.title)
                }
            } else {
                addNewTab()
            }
        } else {
            addNewTab()
        }
        loadHistory()
    }

    private func saveTabs() {
        let tabStates = tabs.enumerated().map { index, _ in
            TabState(
                url: tabURLs[index] ?? "",
                title: tabTitles[index] ?? "New Tab"
            )
        }
        if let encoded = try? JSONEncoder().encode(tabStates) {
            UserDefaults.standard.set(encoded, forKey: tabsKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "browserHistory"),
           let savedHistory = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.history = savedHistory
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "browserHistory")
        }
    }

    func addNewTab() {
        addNewTab(withURL: "", title: "New Tab")
    }

    func addNewTab(withURL url: String = "", title: String = "New Tab") {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        
        let dataStore = WKWebsiteDataStore.nonPersistent()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = settingsManager.privacySettings.enableJavaScript
        webConfiguration.defaultWebpagePreferences = prefs
        webConfiguration.websiteDataStore = settingsManager.privacySettings.allowThirdPartyCookies ? 
            .default() : dataStore

        let newWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        newWebView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        newWebView.navigationDelegate = self
        newWebView.allowsLinkPreview = true

        tabs.append(newWebView)
        let newIndex = tabs.count - 1
        selectedTabIndex = newIndex
        tabTitles[newIndex] = title
        
        if !url.isEmpty, let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            newWebView.load(request)
            tabURLs[newIndex] = url.absoluteString
        } else if let url = URL(string: homePage) {
            var request = URLRequest(url: url)
            request.setValue("1", forHTTPHeaderField: "DNT")
            newWebView.load(request)
            tabURLs[newIndex] = ""
        }
        saveTabs()
        configureWebView(newWebView)
    }

    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count, tabs.count > 1 else { return }
        
        tabs[index].removeFromSuperview()
        tabs.remove(at: index)
        
        var newTabURLs: [Int: String] = [:]
        var newTabTitles: [Int: String] = [:]
        var newTabFavicons: [Int: NSImage] = [:]
        
        for i in 0..<tabs.count {
            let oldIndex = i >= index ? i + 1 : i
            
            if let url = tabURLs[oldIndex] {
                newTabURLs[i] = url
            }
            if let title = tabTitles[oldIndex] {
                newTabTitles[i] = title
            }
            if let favicon = tabFavicons[oldIndex] {
                newTabFavicons[i] = favicon
            }
        }
        
        tabURLs = newTabURLs
        tabTitles = newTabTitles
        tabFavicons = newTabFavicons
        
        selectedTabIndex = min(index, tabs.count - 1)
        saveTabs()
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
            webView.evaluateJavaScript("""
                (function() {
                    var links = document.getElementsByTagName('link');
                    for (var i = 0; i < links.length; i++) {
                        if ((links[i].rel === 'icon') || 
                            (links[i].rel === 'shortcut icon') || 
                            (links[i].rel === 'apple-touch-icon')) {
                            return links[i].href;
                        }
                    }
                    return new URL('/favicon.ico', document.baseURI).href;
                })()
            """) { [weak self] (result, error) in
                if let faviconURL = result as? String,
                   let url = URL(string: faviconURL) {
                    URLSession.shared.dataTask(with: url) { data, response, error in
                        if let data = data, let image = NSImage(data: data) {
                            DispatchQueue.main.async {
                                self?.tabFavicons[index] = image
                            }
                        }
                    }.resume()
                }
            }
            
            // Get title and save history
            webView.evaluateJavaScript("document.title") { [weak self] (result, error) in
                DispatchQueue.main.async {
                    if let title = result as? String {
                        self?.tabTitles[index] = title
                        if let url = webView.url?.absoluteString {
                            self?.tabURLs[index] = url
                            self?.saveTabs()
                        }
                    }
                }
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

    func addToHistory(title: String, url: String) {
        let favicon = tabFavicons[selectedTabIndex]
        let faviconData = favicon?.tiffRepresentation
        
        let item = HistoryItem(
            id: UUID(),
            title: title,
            url: url,
            date: Date(),
            faviconData: faviconData
        )
        
        history.append(item)
        saveHistory()
    }

    private func configureWebView(_ webView: WKWebView) {
        let preferences = WKWebpagePreferences()
        let urlString = webView.url?.absoluteString ?? ""
        
        if let matchingRule = settingsManager.privacySettings.siteRules.first(where: { $0.matches(url: urlString) }) {
            preferences.allowsContentJavaScript = matchingRule.allowJavaScript ?? settingsManager.privacySettings.enableJavaScript
            
            if let allowCookies = matchingRule.allowThirdPartyCookies {
                let dataStore = allowCookies ? WKWebsiteDataStore.default() : WKWebsiteDataStore.nonPersistent()
                webView.configuration.websiteDataStore = dataStore
            }
        } else {
            preferences.allowsContentJavaScript = settingsManager.privacySettings.enableJavaScript
            let dataStore = settingsManager.privacySettings.allowThirdPartyCookies ? 
                WKWebsiteDataStore.default() : WKWebsiteDataStore.nonPersistent()
            webView.configuration.websiteDataStore = dataStore
        }
        
        webView.configuration.defaultWebpagePreferences = preferences
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
                        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
                        .sidebarHover(isVisible: $sidebarManager.isVisible)

                        Spacer()
                    }
                    .frame(width: 250)
                    .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
                    .sidebarHover(isVisible: $sidebarManager.isVisible)
                }

                // Main browser content
                VStack(spacing: 0) {
                    if !viewModel.tabs.isEmpty {
                        ContentView(viewModel: viewModel, tabIndex: viewModel.selectedTabIndex)
                    } else {
                        VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
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

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffect())
    }
}
