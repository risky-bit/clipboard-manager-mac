import SwiftUI

struct PopupView: View {
    @Bindable var store: ClipboardStore  // @Bindable for @Observable objects
    let onSelect: (ClipboardItem) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex = 0
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var filtered: [ClipboardItem] {
        let items = store.items  // Explicit access to trigger observation
        guard !searchText.isEmpty else {
            log("[PopupView] No search text - returning all \(items.count) items")
            return items
        }

        let result = items.filter { item in
            if case .text(let text) = item.content {
                let matches = text.localizedCaseInsensitiveContains(searchText)
                log("[PopupView] Testing '\(text.prefix(30))' against '\(searchText)': \(matches)")
                return matches
            }
            return true  // Always show images in search results
        }

        log("[PopupView] Search '\(searchText)' returned \(result.count) of \(items.count) items")
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider()
            itemList
            Divider()
            footer
        }
        .frame(width: 420, height: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .id(store.items.count)  // Force view to rebuild when item count changes
        .onAppear {
            log("[PopupView] onAppear - store.items.count: \(store.items.count)")
            log("[PopupView] Items: \(store.items.map { $0.preview.prefix(20) }.joined(separator: ", "))")
            selectedIndex = 0
            searchFocused = true
        }
        .onChange(of: searchText) { oldValue, newValue in
            log("[PopupView] searchText changed from '\(oldValue)' to '\(newValue)'")
            selectedIndex = 0
        }
        .onChange(of: store.items) { _, newItems in
            log("[PopupView] store.items CHANGED! New count: \(newItems.count)")
            log("[PopupView] New items: \(newItems.map { $0.preview.prefix(20) }.joined(separator: ", "))")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        ZStack {
            // Drag handle in the center
            HStack {
                Spacer()
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 3)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 3)
                }
                Spacer()
            }

            // Close button overlaid on top right
            HStack {
                Spacer()
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search clipboard history...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)
                .onKeyPress(.escape)    { onDismiss(); return .handled }
                .onKeyPress(.upArrow)   { move(by: -1); return .handled }
                .onKeyPress(.downArrow) { move(by: 1); return .handled }
                .onKeyPress(.return)    { selectCurrent(); return .handled }
        }
        .padding(12)
    }

    private var itemList: some View {
        Group {
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { i, item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: i == selectedIndex,
                                    onSelect: { onSelect(item) },
                                    onDelete: { store.remove(item) }
                                )
                                .id(i)
                                if i < filtered.count - 1 {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .id(searchText)  // Force rebuild when search changes
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "Nothing copied yet" : "No matches")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }

    private var footer: some View {
        HStack {
            Text(
                store.items.isEmpty
                    ? "Empty"
                    : "\(store.items.count) item\(store.items.count == 1 ? "" : "s")"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)

            Spacer()

            Button("Clear All") { store.clear() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Keyboard navigation

    private func move(by delta: Int) {
        guard !filtered.isEmpty else { return }
        selectedIndex = max(0, min(filtered.count - 1, selectedIndex + delta))
    }

    private func selectCurrent() {
        guard !filtered.isEmpty, selectedIndex < filtered.count else { return }
        onSelect(filtered[selectedIndex])
    }
}
