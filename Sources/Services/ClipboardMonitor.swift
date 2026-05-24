import AppKit
import Foundation

class ClipboardMonitor {
    private let store: ClipboardStore
    private var timer: Timer?
    private var changeCount: Int

    init(store: ClipboardStore) {
        self.store = store
        self.changeCount = NSPasteboard.general.changeCount
        log("[ClipboardMonitor] Initialized with changeCount: \(changeCount)")
    }

    func start() {
        log("[ClipboardMonitor] Starting timer...")
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        log("[ClipboardMonitor] Timer started: \(timer != nil)")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func skipNextChange() {
        changeCount = NSPasteboard.general.changeCount
    }

    private func checkForChanges() {
        log("[ClipboardMonitor] Poll tick - checking clipboard...")

        // Create a NEW pasteboard instance each time to avoid caching
        let pasteboard = NSPasteboard.general

        // Force it to sync with system by releasing cached data
        _ = pasteboard.types  // Force type check

        let currentChangeCount = pasteboard.changeCount

        log("[ClipboardMonitor] Current changeCount: \(currentChangeCount), Last: \(changeCount)")

        // Check if pasteboard changed
        guard currentChangeCount != changeCount else {
            log("[ClipboardMonitor] No change detected")
            return
        }

        log("[ClipboardMonitor] CHANGE DETECTED!")

        // Update changeCount FIRST (like Maccy does)
        changeCount = currentChangeCount

        // Check for image first (higher priority)
        if let imageType = pasteboard.availableType(from: [.tiff, .png]) {
            log("[ClipboardMonitor] Image type detected: \(imageType.rawValue)")

            if let data = pasteboard.data(forType: imageType),
               let image = NSImage(data: data) {
                log("[ClipboardMonitor] Adding image: \(image.size.width)x\(image.size.height)")

                DispatchQueue.main.async {
                    self.store.add(.image(image))
                }
                return
            }
        }

        // Fall back to text
        guard let stringType = pasteboard.availableType(from: [.string]) else {
            log("[ClipboardMonitor] No string type available")
            return
        }

        // Read the data directly
        guard let data = pasteboard.data(forType: stringType),
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty else {
            log("[ClipboardMonitor] Failed to read data")
            return
        }

        // Debug: Print what we're adding
        log("[ClipboardMonitor] Adding text: '\(text.prefix(50))'")

        DispatchQueue.main.async {
            self.store.add(.text(text))
        }
    }
}
