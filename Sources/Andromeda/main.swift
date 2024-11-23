//
//  main.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            if let iconImage = NSImage(contentsOfFile: Bundle.module.path(forResource: "AppIcon", ofType: "icns") ?? "") {
                Image(nsImage: iconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            
            Text("Andromeda")
                .font(.system(size: 24, weight: .bold))
            Text("Version 1.0")
                .font(.system(size: 14))
            Text("© 2024 WithAndromeda")
                .font(.system(size: 14))
            Text("A secure, fast, efficient and lightweight web browser")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
        }
        .padding(40)
        .frame(width: 400, height: 400)
    }
}

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CustomWindow!
    var viewModel: ViewModel?
    var aboutWindow: NSWindow?
    var sidebarManager: SidebarManager!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: iconURL) {
            let iconSize = NSSize(width: 104, height: 104)
            image.size = iconSize
            
            image.isTemplate = false
            NSApp.applicationIconImage = image
            
            let dockImage = NSImage(size: iconSize)
            dockImage.lockFocus()
            
            let bounds = NSRect(origin: .zero, size: iconSize)
            let path = NSBezierPath(roundedRect: bounds, xRadius: bounds.width * 0.225, yRadius: bounds.height * 0.225)
            path.addClip()
            
            image.draw(in: bounds)
            dockImage.unlockFocus()
            
            let imageView = NSImageView(frame: bounds)
            imageView.image = dockImage
            NSApp.dockTile.contentView = imageView
            NSApp.dockTile.display()
        }
        
        viewModel = ViewModel()
        sidebarManager = SidebarManager()
        let contentView = BrowserView()
            .environmentObject(viewModel!)
            .environmentObject(sidebarManager)

        window = CustomWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1300, height: 850),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()

        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        
        setupMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "About Andromeda", action: #selector(showAboutWindow), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Andromeda", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // File Menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: "t"))
        fileMenu.addItem(NSMenuItem(title: "Close Tab", action: #selector(closeTab), keyEquivalent: "w"))

        // Edit Menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu

        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Find", action: #selector(ViewModel.performFindPanelAction(_:)), keyEquivalent: "f"))

        // View Menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        viewMenu.addItem(NSMenuItem(title: "Toggle Sidebar", action: #selector(toggleSidebar), keyEquivalent: "s"))
        viewMenu.addItem(NSMenuItem(title: "Reload Page", action: #selector(reloadPage), keyEquivalent: "r"))
        
        // History Menu
        let historyMenuItem = NSMenuItem()
        mainMenu.addItem(historyMenuItem)
        let historyMenu = NSMenu(title: "History")
        historyMenuItem.submenu = historyMenu
        historyMenu.addItem(NSMenuItem(title: "Back", action: #selector(goBack), keyEquivalent: "["))
        historyMenu.addItem(NSMenuItem(title: "Forward", action: #selector(goForward), keyEquivalent: "]"))
    }

    @objc func showAboutWindow() {
        if aboutWindow == nil {
            let aboutView = NSHostingView(rootView: AboutView())
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 400, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Andromeda"
            aboutWindow?.contentView = aboutView
        }
        aboutWindow?.center()
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func newTab() {
        viewModel?.addNewTab()
    }

    @objc func closeTab() {
        viewModel?.closeTab(at: viewModel?.selectedTabIndex ?? 0)
    }

    @objc func toggleSidebar() {
        sidebarManager.toggle()
    }

    @objc func reloadPage() {
        viewModel?.reload()
    }

    @objc func goBack() {
        viewModel?.goBack()
    }

    @objc func goForward() {
        viewModel?.goForward()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
