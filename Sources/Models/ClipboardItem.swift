import Foundation
import AppKit

enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)

    static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            return a.tiffRepresentation == b.tiffRepresentation
        default:
            return false
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let content: ClipboardContent
    let date: Date

    init(content: ClipboardContent, date: Date = .now) {
        self.id = UUID()
        self.content = content
        self.date = date
    }

    var preview: String {
        switch content {
        case .text(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return "[Image]"
        }
    }

    var isImage: Bool {
        if case .image = content { return true }
        return false
    }

    var text: String? {
        if case .text(let text) = content { return text }
        return nil
    }

    var image: NSImage? {
        if case .image(let image) = content { return image }
        return nil
    }
}
