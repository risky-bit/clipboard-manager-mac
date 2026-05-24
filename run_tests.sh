#!/bin/bash

# ClipboardManager Test Runner
# Run this after each build to verify core functionality

set -e

echo "🧪 ClipboardManager Test Suite"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED=0
PASSED=0

# Test helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Clear old logs
echo "Clearing debug logs..."
> /tmp/clipboard_debug.log

# Test 1: Build exists
echo ""
echo "Test 1: Checking build artifacts..."
if [ -f ".build/release/ClipboardManager" ]; then
    pass "Binary exists at .build/release/ClipboardManager"
else
    fail "Binary missing - run 'swift build -c release' first"
fi

if [ -d "ClipboardManager.app" ]; then
    pass "App bundle exists"
else
    fail "App bundle missing"
fi

if [ -f "ClipboardManager.app/Contents/MacOS/ClipboardManager" ]; then
    pass "Executable exists in app bundle"
else
    fail "Executable missing from app bundle"
fi

if [ -f "ClipboardManager.app/Contents/Info.plist" ]; then
    pass "Info.plist exists"
else
    fail "Info.plist missing"
fi

# Test 2: Package.swift is valid
echo ""
echo "Test 2: Validating Package.swift..."
if swift package describe > /dev/null 2>&1; then
    pass "Package.swift is valid"
else
    fail "Package.swift has errors"
fi

# Test 3: Source files exist
echo ""
echo "Test 3: Checking source files..."
REQUIRED_FILES=(
    "Sources/AppDelegate.swift"
    "Sources/Main.swift"
    "Sources/Models/ClipboardItem.swift"
    "Sources/Services/ClipboardMonitor.swift"
    "Sources/Services/ClipboardStore.swift"
    "Sources/Services/HotKeyManager.swift"
    "Sources/Views/PopupView.swift"
    "Sources/Views/ClipboardItemRow.swift"
    "Sources/Utils.swift"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        pass "Found $file"
    else
        fail "Missing $file"
    fi
done

# Test 4: Info.plist has required keys
echo ""
echo "Test 4: Validating Info.plist..."
if /usr/libexec/PlistBuddy -c "Print LSUIElement" ClipboardManager.app/Contents/Info.plist | grep -q "true"; then
    pass "LSUIElement is true (menu bar app)"
else
    fail "LSUIElement should be true"
fi

# Test 5: Check if app is running
echo ""
echo "Test 5: App status..."
if pgrep -x "ClipboardManager" > /dev/null; then
    pass "ClipboardManager is running (PID: $(pgrep -x ClipboardManager))"

    # Test 6: Check logs for initialization
    echo ""
    echo "Test 6: Checking app logs..."
    sleep 2  # Give app time to initialize

    if grep -q "App launched" /tmp/clipboard_debug.log; then
        pass "App launched successfully"
    else
        fail "App launch not logged"
    fi

    if grep -q "Clipboard monitor started" /tmp/clipboard_debug.log; then
        pass "Clipboard monitor started"
    else
        fail "Clipboard monitor not started"
    fi

    if grep -q "Hotkey registered" /tmp/clipboard_debug.log; then
        pass "Hotkey (Cmd+Shift+V) registered"
    else
        fail "Hotkey not registered"
    fi

    # Test 7: Accessibility check
    echo ""
    echo "Test 7: Accessibility permissions..."
    if grep -q "Accessibility trusted: true" /tmp/clipboard_debug.log; then
        pass "Accessibility permissions granted"
    else
        warn "Accessibility permissions NOT granted - paste will not work"
        echo "  → Go to System Settings → Privacy & Security → Accessibility"
        echo "  → Add ClipboardManager.app and toggle ON"
    fi
else
    warn "ClipboardManager is not running"
    echo "  Start it with: open ClipboardManager.app"
fi

# Test 8: Clipboard monitoring
echo ""
echo "Test 8: Clipboard monitoring (interactive)..."
warn "Skipping interactive test - run manually:"
echo "  1. Copy some text (Cmd+C)"
echo "  2. Check logs: tail -5 /tmp/clipboard_debug.log | grep CHANGE"
echo "  3. Should see 'CHANGE DETECTED' and the text you copied"

# Summary
echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    echo ""
    echo "✨ Ready for manual testing"
    echo "📋 See TESTS.md for full test checklist"
fi
