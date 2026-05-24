import Foundation
import Observation

@Observable
class ClipboardStore {
    var items: [ClipboardItem] = []

    private let maxItems = 25

    func add(_ content: ClipboardContent) {
        // Skip empty text
        if case .text(let text) = content {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            log("[ClipboardStore] add() called with text: '\(text.prefix(50))'")
        } else {
            log("[ClipboardStore] add() called with image")
        }

        log("[ClipboardStore] Current items count BEFORE: \(items.count)")

        // Remove duplicate if exists
        items.removeAll { $0.content == content }
        // Insert at beginning
        items.insert(ClipboardItem(content: content), at: 0)

        // Trim to max items
        if items.count > maxItems {
            items.removeLast()
        }

        log("[ClipboardStore] Current items count AFTER: \(items.count)")
        log("[ClipboardStore] Items: \(items.map { $0.preview.prefix(20) }.joined(separator: ", "))")
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items.removeAll()
    }
}
