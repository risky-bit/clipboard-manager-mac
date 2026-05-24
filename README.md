# ClipboardManager

A lightweight, native macOS clipboard history manager built with Swift and SwiftUI. Press **⌘⇧V** anywhere to see your recent clipboard items, search through them, and paste instantly.

## ✨ Features

- 📋 **Clipboard History** - Stores up to 25 recent items (text + images)
- 🖼️ **Image Support** - Copy and paste images with thumbnails
- 🔍 **Live Search** - Filter clipboard history as you type
- ⌨️ **Keyboard Navigation** - Arrow keys, Enter, Escape
- 🎯 **Live Updates** - New items appear immediately while popup is open
- 🪟 **Draggable Window** - Move popup anywhere on screen
- 🚀 **Lightweight** - Menu bar app, minimal resources
- 🔄 **Smart Paste** - Auto-pastes into the app you were using

## 🚀 Installation

### Option 1: Download Prebuilt App (Recommended)

1. Download **ClipboardManager-macOS.zip** from the [latest release](https://github.com/risky-bit/clipboard-manager-mac/releases/latest)
2. Unzip and move **ClipboardManager.app** to `/Applications`
3. Open the app - it appears in your menu bar (📋)
4. Press **⌘⇧V** to start using it!

### Option 2: Build from Source

**Requirements:**
- macOS 14.0+ (Sonoma or later)
- Swift 5.9+ (Xcode 15+ OR command-line tools)

**Quick build:**

```bash
# Clone the repository
git clone https://github.com/risky-bit/clipboard-manager-mac.git
cd clipboard-manager-mac

# Build the app
swift build -c release

# Copy binary to app bundle
cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/

# Launch
open ClipboardManager.app
```

The app will appear in your menu bar with a clipboard icon 📋

### Option 3: Build with Xcode

1. Open the project in Xcode
2. Disable App Sandbox (Signing & Capabilities)
3. Press ⌘R to build and run

## 📖 Usage

### Basic Usage

| Action | How |
|--------|-----|
| **Open history** | `Cmd+Shift+V` |
| **Search** | Just start typing |
| **Navigate** | `↑` / `↓` arrow keys |
| **Paste** | Click item or press `Enter` |
| **Close** | Click ✕ or press `Escape` |
| **Delete item** | Hover and click trash icon |
| **Clear all** | Click "Clear All" in footer |
| **Drag window** | Click and drag hamburger icon |

### Menu Bar

Right-click the menu bar icon for:
- Show History (⌘⇧V)
- Clear History
- Quit

## ⚙️ Permissions

### Accessibility Permission (Required for Paste)

ClipboardManager needs **Accessibility** permission to paste items into other apps.

**How to grant:**

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button
3. Navigate to and select `ClipboardManager.app`
4. Toggle it **ON**

**Note:** After rebuilding during development, you'll need to re-grant this permission (code signature changes).

## 🛠️ Troubleshooting

### Paste doesn't work
- ✅ Check **Accessibility permissions** (see above)
- ✅ Verify in logs: `tail /tmp/clipboard_debug.log | grep "Accessibility"`
  - Should show: `Accessibility trusted: true`

### New items don't appear
- ✅ Items update live while popup is open
- ✅ If something looks wrong, close and reopen popup (`Cmd+Shift+V`)

### Search not working
- ✅ Make sure you can type in the search box
- ✅ Search is case-insensitive partial matching
- ✅ Images always show in search results

### App doesn't launch
- ✅ Check if binary exists: `ls ClipboardManager.app/Contents/MacOS/ClipboardManager`
- ✅ Rebuild: `swift build -c release && cp .build/release/ClipboardManager ClipboardManager.app/Contents/MacOS/`

## 🧪 Testing

Run the stress test to verify everything works:

```bash
chmod +x stress_test.sh
./stress_test.sh
```

This tests:
- Rapid copying (170+ items)
- Large text (10KB+ items)
- Unicode and special characters
- 25-item limit
- Empty/whitespace handling

## 🏗️ Project Structure

```
clipboard/
├── Sources/
│   ├── Main.swift                  # App entry point
│   ├── AppDelegate.swift           # Main app logic, popup, paste
│   ├── KeyablePanel.swift          # Custom NSPanel (accepts keyboard input)
│   ├── Utils.swift                 # Debug logging
│   ├── Models/
│   │   └── ClipboardItem.swift     # Data model (text + images)
│   ├── Services/
│   │   ├── ClipboardMonitor.swift  # Monitors system clipboard (0.5s polling)
│   │   ├── ClipboardStore.swift    # @Observable store (25-item limit)
│   │   └── HotKeyManager.swift     # Global hotkey (Cmd+Shift+V)
│   └── Views/
│       ├── PopupView.swift         # Main popup UI (search + list)
│       └── ClipboardItemRow.swift  # Individual item row
├── Package.swift                   # Swift Package Manager config
├── Info.plist                      # LSUIElement = true (menu bar app)
├── TESTS.md                        # Manual test cases
├── stress_test.sh                  # Automated stress testing
└── README.md                       # This file
```

## 🔧 Architecture

- **SwiftUI + AppKit Hybrid**: SwiftUI views in NSPanel (via NSHostingView)
- **Reactive State**: Uses Swift's `@Observable` macro for live updates
- **Background Monitoring**: Timer-based clipboard polling (0.5s interval)
- **Window Management**: Reuses single window (not rebuilt on every open)

## 🗺️ Roadmap

### ✅ Completed
- [x] Clipboard history (text + images)
- [x] Live updates
- [x] Search
- [x] Keyboard navigation
- [x] Draggable window
- [x] Image thumbnails
- [x] Stress testing

### 🎯 Planned
- [ ] Persistent storage (survive restarts)
- [ ] Quick access hotkeys (Cmd+1-9)
- [ ] Pinned/favorite items
- [ ] File path support
- [ ] App icon
- [ ] Brew installation

## 📝 License

MIT License - see LICENSE file

## 🙏 Acknowledgments

Inspired by [Maccy](https://github.com/p0deje/Maccy) and [Clipy](https://github.com/Clipy/Clipy)

---

**Built with ❤️ using Swift and SwiftUI**
