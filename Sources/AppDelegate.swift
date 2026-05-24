import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popupWindow: NSPanel?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotKeyManager: HotKeyManager?
    private var previousApp: NSRunningApplication?

    let store = ClipboardStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] App launched!")

        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()

        print("[AppDelegate] Creating clipboard monitor...")
        clipboardMonitor = ClipboardMonitor(store: store)
        clipboardMonitor?.start()
        print("[AppDelegate] Clipboard monitor started")

        hotKeyManager = HotKeyManager { [weak self] in
            self?.togglePopup()
        }
        hotKeyManager?.register()
        print("[AppDelegate] Hotkey registered")

        requestAccessibilityIfNeeded()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show History  ⌘⇧V", action: #selector(openPopup), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit ClipboardManager", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func clearHistory() {
        store.clear()
    }

    // MARK: - Popup lifecycle

    func togglePopup() {
        if let window = popupWindow, window.isVisible {
            closePopup()
        } else {
            openPopup()
        }
    }

    @objc func openPopup() {
        log("[AppDelegate] openPopup() called")
        log("[AppDelegate] store.items.count: \(store.items.count)")
        log("[AppDelegate] Store items: \(store.items.map { $0.preview.prefix(20) }.joined(separator: ", "))")

        previousApp = NSWorkspace.shared.frontmostApplication

        // Build popup window once and reuse (like Maccy does)
        if popupWindow == nil {
            log("[AppDelegate] Building popup window")
            buildPopupWindow()
        }

        positionPopupOnScreen()
        popupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePopup() {
        popupWindow?.orderOut(nil)
    }

    private func buildPopupWindow() {
        let view = PopupView(store: store) { [weak self] item in
            self?.paste(item)
        } onDismiss: { [weak self] in
            self?.closePopup()
        }

        let panel = KeyablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]

        // Enable dragging the window by clicking anywhere
        panel.isMovableByWindowBackground = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popupDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )

        popupWindow = panel
    }

    @objc private func popupDidResignKey() {
        // Don't auto-close when losing focus - let user close manually with X or Escape
    }

    private func positionPopupOnScreen() {
        guard let screen = NSScreen.main else { return }
        let size = CGSize(width: 420, height: 520)
        let origin = CGPoint(
            x: screen.visibleFrame.midX - size.width / 2,
            y: screen.visibleFrame.midY - size.height / 2
        )
        popupWindow?.setFrame(CGRect(origin: origin, size: size), display: true)
    }

    // MARK: - Paste

    func paste(_ item: ClipboardItem) {
        log("[AppDelegate] paste() called with: '\(item.preview.prefix(50))'")
        log("[AppDelegate] previousApp: \(previousApp?.localizedName ?? "nil")")

        // Set clipboard based on content type
        NSPasteboard.general.clearContents()

        switch item.content {
        case .text(let text):
            NSPasteboard.general.setString(text, forType: .string)
            log("[AppDelegate] Clipboard set with text")
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                NSPasteboard.general.setData(tiffData, forType: .tiff)
                log("[AppDelegate] Clipboard set with image: \(image.size.width)x\(image.size.height)")
            }
        }

        // Tell the monitor to skip this change since we made it ourselves
        clipboardMonitor?.skipNextChange()

        // Keep popup open - just activate target app and paste
        let target = previousApp
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            log("[AppDelegate] Activating target app: \(target?.localizedName ?? "nil")")
            target?.activate()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                log("[AppDelegate] Simulating Cmd+V")
                self.simulateCommandV()
            }
        }
    }

    private func simulateCommandV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        down?.flags = .maskCommand
        up?.flags   = .maskCommand

        log("[AppDelegate] Posting Cmd+V events - down: \(down != nil), up: \(up != nil)")
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        log("[AppDelegate] Cmd+V events posted")
    }

    // MARK: - Permissions

    private func requestAccessibilityIfNeeded() {
        // Always prompt with the option to open System Settings
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(opts as CFDictionary)
        log("[AppDelegate] Accessibility trusted: \(trusted)")

        if !trusted {
            log("[AppDelegate] MISSING ACCESSIBILITY PERMISSIONS - paste will not work!")
            // Show alert to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "ClipboardManager needs Accessibility permission to paste items. Please grant permission in System Settings."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}
