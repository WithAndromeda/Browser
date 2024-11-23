//
//  main.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

import Foundation
#if os(macOS)
import AppKit
import SwiftUI
import WebKit


@_exported import class AppKit.NSImage

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            if let iconImage = NSImage(
                contentsOfFile: Bundle.module.path(forResource: "AppIcon", ofType: "icns") ?? "")
            {
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
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(
        contentRect: NSRect, styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear

        if let contentView = self.contentView {
            contentView.wantsLayer = true

            let visualEffectView = NSVisualEffectView(frame: contentRect)
            visualEffectView.wantsLayer = true
            visualEffectView.material = .windowBackground
            visualEffectView.state = .active
            visualEffectView.blendingMode = .behindWindow

            contentView.addSubview(visualEffectView)
            visualEffectView.autoresizingMask = [.width, .height]
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let titleBarHeight = 28.0
        
        if locationInWindow.y >= frame.height - titleBarHeight {
            super.mouseDragged(with: event)
        }
    }
}

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.hudWindow, .titled, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var viewModel: ViewModel?
    var window: CustomWindow?
    var aboutWindow: NSWindow?
    var historyWindow: NSWindow?
    var settingsWindow: NSWindow?
    var sidebarManager = SidebarManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
            let image = NSImage(contentsOf: iconURL)
        {
            let iconSize = NSSize(width: 104, height: 104)
            image.size = iconSize

            image.isTemplate = false
            NSApp.applicationIconImage = image

            let dockImage = NSImage(size: iconSize)
            dockImage.lockFocus()

            let bounds = NSRect(origin: .zero, size: iconSize)
            let path = NSBezierPath(
                roundedRect: bounds, xRadius: bounds.width * 0.225, yRadius: bounds.height * 0.225)
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
            contentRect: NSRect(x: 100, y: 100, width: 1280, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window?.titleVisibility = .visible
        window?.titlebarAppearsTransparent = false
        window?.standardWindowButton(.closeButton)?.isHidden = false
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window?.standardWindowButton(.zoomButton)?.isHidden = false

        window?.collectionBehavior = [.fullScreenPrimary]
        window?.center()

        let hostingView = NSHostingView(rootView: contentView)
        window?.contentView = hostingView
        window?.makeKeyAndOrderFront(nil)

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
        appMenu.addItem(
            NSMenuItem(
                title: "About Andromeda", action: #selector(showAboutWindow), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit Andromeda", action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))

        // File Menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(
            NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: "t"))
        fileMenu.addItem(
            NSMenuItem(title: "Close Tab", action: #selector(closeTab), keyEquivalent: "w"))

        // Edit Menu
        let editMenuItem = NSMenuItem()
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
            NSMenuItem(
                title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(
            NSMenuItem(
                title: "Find", action: #selector(ViewModel.performFindPanelAction(_:)),
                keyEquivalent: "f"))

        // View Menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        viewMenu.addItem(
            NSMenuItem(
                title: "Toggle Sidebar", action: #selector(toggleSidebar), keyEquivalent: "s"))
        viewMenu.addItem(
            NSMenuItem(title: "Reload Page", action: #selector(reloadPage), keyEquivalent: "r"))

        // History Menu
        let historyMenuItem = NSMenuItem()
        mainMenu.addItem(historyMenuItem)
        let historyMenu = NSMenu(title: "History")
        historyMenuItem.submenu = historyMenu
        historyMenu.addItem(
            NSMenuItem(title: "Back", action: #selector(goBack), keyEquivalent: "["))
        historyMenu.addItem(
            NSMenuItem(title: "Forward", action: #selector(goForward), keyEquivalent: "]"))
        historyMenu.addItem(NSMenuItem.separator())
        historyMenu.addItem(
            NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "y"))

        // Settings Menu
        let settingsMenuItem = NSMenuItem()
        settingsMenuItem.title = "Settings"
        mainMenu.addItem(settingsMenuItem)
        let settingsMenu = NSMenu(title: "Settings")
        settingsMenuItem.submenu = settingsMenu

        settingsMenu.addItem(
            NSMenuItem(
                title: "Preferences...",
                action: #selector(AppDelegate.showSettings),
                keyEquivalent: ","))

        // Window Menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(
            NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(
            NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(
            NSMenuItem(title: "Hide Andromeda", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        windowMenu.addItem(
            NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
                .with({ $0.keyEquivalentModifierMask = [.command, .option] }))
        windowMenu.addItem(
            NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
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

    @objc func showHistory() {
        if historyWindow == nil {
            historyWindow = FloatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400)
            )
            historyWindow?.delegate = self
        }
        
        let historyView = NSHostingView(rootView: 
            HistoryView(closeAction: { [weak self] in
                self?.historyWindow?.close()
            })
            .environmentObject(viewModel!)
        )
        
        historyWindow?.contentView = historyView
        
        if let mainWindow = self.window {
            let mainFrame = mainWindow.frame
            let historyFrame = historyWindow?.frame ?? .zero
            let x = mainFrame.midX - historyFrame.width/2
            let y = mainFrame.midY - historyFrame.height/2
            historyWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            historyWindow?.center()
        }
        
        historyWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = FloatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400)
            )
            settingsWindow?.delegate = self
        }
        
        let settingsView = NSHostingView(rootView: 
            SettingsView(
                settingsManager: viewModel?.settingsManager ?? SettingsManager(),
                closeAction: { [weak self] in
                    self?.settingsWindow?.close()
                }
            )
        )
        settingsWindow?.contentView = settingsView
        
        if let mainWindow = self.window {
            let mainFrame = mainWindow.frame
            let settingsFrame = settingsWindow?.frame ?? .zero
            let x = mainFrame.midX - settingsFrame.width/2
            let y = mainFrame.midY - settingsFrame.height/2
            settingsWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            settingsWindow?.center()
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            switch window {
            case settingsWindow:
                settingsWindow = nil
            case historyWindow:
                historyWindow = nil
            case aboutWindow:
                aboutWindow = nil
            case self.window:
                NSApplication.shared.terminate(self)
            default:
                break
            }
        }
    }
}

extension NSMenuItem {
    func with(_ configure: (NSMenuItem) -> Void) -> NSMenuItem {
        configure(self)
        return self
    }
}
#endif

func main() {
    #if os(macOS)
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate

    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)
    app.run()
    #else
    NotImplementedException()
    ThrowFatalException("Not implemented for this platform")
    #endif
}

main()
