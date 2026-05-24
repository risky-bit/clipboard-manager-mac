# ClipboardManager Test Cases

## Test Checklist

Run through these tests after each build to ensure no regressions.

---

### 1. App Launch & Menu Bar
- [ ] App launches without errors
- [ ] Menu bar icon appears (clipboard icon)
- [ ] Clicking menu bar icon shows menu with:
  - "Show History  ⌘⇧V"
  - "Clear History"
  - "Quit ClipboardManager"

---

### 2. Clipboard Monitoring
**Test Steps:**
1. Copy some text (Cmd+C) from any app
2. Wait 1 second
3. Press Cmd+Shift+V to open popup
4. Verify the copied text appears at the top of the list

**Expected Result:**
- ✅ New clipboard items appear in history immediately
- ✅ Most recent item is at the top
- ✅ Duplicate items are moved to top (not duplicated)
- ✅ History limited to 25 items

**How to verify:**
```bash
# Check logs for clipboard changes
tail -20 /tmp/clipboard_debug.log | grep "CHANGE DETECTED"
```

---

### 3. Popup Window - Opening
**Test Steps:**
1. Press Cmd+Shift+V

**Expected Result:**
- ✅ Popup appears centered on screen
- ✅ Size is 420x520 pixels
- ✅ Has rounded corners and shadow
- ✅ Has translucent background (regularMaterial)

---

### 4. Popup Window - UI Elements
**Visual Checklist:**
- [ ] Drag handle (two horizontal lines) visible at top center
- [ ] Close button (X) visible at top right
- [ ] Search bar with magnifying glass icon
- [ ] List of clipboard items below search
- [ ] Footer showing item count
- [ ] "Clear All" button in footer

---

### 5. Popup Window - Dragging
**Test Steps:**
1. Open popup (Cmd+Shift+V)
2. Click and drag anywhere on the popup window

**Expected Result:**
- ✅ Window can be dragged to any position on screen
- ✅ Drag handle provides visual affordance

---

### 6. Search Functionality
**Test Steps:**
1. Open popup
2. Type search query in search bar
3. Verify list filters in real-time

**Expected Result:**
- ✅ Search bar is auto-focused on open
- ✅ Case-insensitive filtering
- ✅ Shows "No matches" if nothing found
- ✅ Shows "Nothing copied yet" if history empty

---

### 7. Keyboard Navigation
**Test Steps:**
1. Open popup
2. Press Down Arrow → selection moves down
3. Press Up Arrow → selection moves up
4. Press Enter → pastes selected item
5. Press Escape → closes popup

**Expected Result:**
- ✅ Arrow keys navigate through items
- ✅ Selected item has highlight
- ✅ List auto-scrolls to keep selection visible
- ✅ Enter triggers paste
- ✅ Escape closes popup

---

### 8. Paste Functionality (REQUIRES ACCESSIBILITY PERMISSIONS)
**Prerequisites:**
- Accessibility permissions granted in System Settings

**Test Steps:**
1. Copy multiple items: "ALPHA", "BRAVO", "CHARLIE"
2. Open popup (Cmd+Shift+V)
3. Click "BRAVO" in the list
4. Verify "BRAVO" is pasted into the target app

**Expected Result:**
- ✅ Popup closes briefly
- ✅ Target app receives focus
- ✅ Cmd+V is simulated
- ✅ Selected text is pasted
- ✅ Popup reopens automatically after paste

**How to verify:**
```bash
# Check logs for paste sequence
tail -40 /tmp/clipboard_debug.log | grep -A 5 "paste()"
```

**Common Issues:**
- If paste doesn't work, check accessibility permissions:
  - System Settings → Privacy & Security → Accessibility
  - ClipboardManager should be listed and toggled ON
- After each rebuild, permissions must be re-granted

---

### 9. Popup Persistence
**Test Steps:**
1. Open popup
2. Click an item to paste
3. Wait for popup to reopen
4. Click another item to paste
5. Repeat multiple times

**Expected Result:**
- ✅ Can paste multiple items without manually reopening popup
- ✅ Popup reopens automatically after each paste
- ✅ No need to press Cmd+Shift+V between pastes

---

### 10. Manual Close
**Test Steps:**
1. Open popup
2. Click the X button in top-right

**Expected Result:**
- ✅ Popup closes immediately

**Alternative:**
1. Open popup
2. Press Escape key

**Expected Result:**
- ✅ Popup closes immediately

---

### 11. Clear History
**Test Steps:**
1. Add several items to history
2. Open popup
3. Click "Clear All" button in footer

**Expected Result:**
- ✅ All items removed from list
- ✅ Shows "Nothing copied yet"
- ✅ Item count shows "Empty"

**Alternative Method:**
1. Click menu bar icon
2. Select "Clear History"

**Expected Result:**
- ✅ History cleared
- ✅ Next popup open shows empty state

---

### 12. Delete Individual Items
**Test Steps:**
1. Open popup
2. Hover over an item
3. Click delete button (trash icon)

**Expected Result:**
- ✅ Item is removed from list
- ✅ Other items remain
- ✅ Item count updates

---

### 13. UI State After Reopen
**Test Steps:**
1. Copy "ITEM1", "ITEM2", "ITEM3"
2. Open popup → verify all 3 items visible
3. Close popup (X button)
4. Copy "ITEM4"
5. Open popup again

**Expected Result:**
- ✅ "ITEM4" appears at top
- ✅ Previous items (ITEM1-3) still visible below
- ✅ NO duplicate items
- ✅ UI shows fresh state (not stale data)

---

### 14. Accessibility Permissions
**Test Steps:**
1. Launch app
2. Check logs for accessibility status

**Expected Result:**
```bash
tail -5 /tmp/clipboard_debug.log | grep "Accessibility"
```
Should show: `Accessibility trusted: true`

**If false:**
- Alert dialog should appear on launch
- Must grant in System Settings → Privacy & Security → Accessibility

---

### 15. No Focus Loss Auto-Close
**Test Steps:**
1. Open popup
2. Click outside popup (on desktop or another app)

**Expected Result:**
- ✅ Popup stays open (does NOT auto-close)
- ✅ User must manually close with X or Escape

---

## Quick Smoke Test

Run this minimal test after each build:

1. ✅ Launch app → menu bar icon appears
2. ✅ Copy "TEST123"
3. ✅ Press Cmd+Shift+V → popup opens with "TEST123" visible
4. ✅ Drag window → window moves
5. ✅ Click "TEST123" → popup closes/reopens, text pastes (if accessibility enabled)
6. ✅ Press Escape → popup closes

---

## Debugging Commands

```bash
# Watch logs in real-time
tail -f /tmp/clipboard_debug.log

# Check recent clipboard changes
grep "CHANGE DETECTED" /tmp/clipboard_debug.log | tail -10

# Check paste events
grep "paste()" /tmp/clipboard_debug.log | tail -10

# Check accessibility status
grep "Accessibility trusted" /tmp/clipboard_debug.log | tail -1

# Clear logs
> /tmp/clipboard_debug.log
```

---

## Known Issues

1. **Paste requires accessibility permissions**
   - Must be re-granted after each rebuild during development
   - System Settings → Privacy & Security → Accessibility

2. **Popup briefly closes/reopens during paste**
   - This is intentional to allow target app to receive focus
   - Alternative: keep popup open but paste won't work reliably

3. **Deprecated API warning**
   - `activateIgnoringOtherApps` deprecated in macOS 14
   - Still works but should be updated for future compatibility
