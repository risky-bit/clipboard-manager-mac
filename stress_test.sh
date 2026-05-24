#!/bin/bash

echo "🧪 ClipboardManager Stress Test"
echo "================================"
echo ""

# Clear logs
> /tmp/clipboard_debug.log

echo "Test 1: Rapid copying (50 items in 5 seconds)"
echo "----------------------------------------------"
for i in {1..50}; do
    echo "Item $i: Test content with number $i" | pbcopy
    sleep 0.1
done
echo "✓ Copied 50 items"
sleep 2

echo ""
echo "Test 2: Large text items (10 items, 10KB each)"
echo "----------------------------------------------"
for i in {1..10}; do
    # Generate 10KB of text
    python3 -c "print('Large text item $i: ' + 'A' * 10000)" | pbcopy
    sleep 0.2
done
echo "✓ Copied 10 large text items"
sleep 2

echo ""
echo "Test 3: Unicode and special characters"
echo "----------------------------------------------"
echo "Hello 世界 🌍 émojis 🎉 symbols ©®™ math ∑∫∂" | pbcopy
sleep 0.5
echo "Ñoño • café • naïve • Zürich" | pbcopy
sleep 0.5
echo "Hebrew: שלום Arabic: مرحبا Russian: Привет" | pbcopy
sleep 0.5
echo "✓ Copied unicode items"
sleep 2

echo ""
echo "Test 4: Empty and whitespace"
echo "----------------------------------------------"
echo "" | pbcopy
sleep 0.5
echo "   " | pbcopy
sleep 0.5
echo $'\n\n\n' | pbcopy
sleep 0.5
echo "✓ Copied empty/whitespace items"
sleep 2

echo ""
echo "Test 5: Very long single line (1MB)"
echo "----------------------------------------------"
python3 -c "print('X' * 1000000)" | pbcopy
sleep 1
echo "✓ Copied 1MB item"
sleep 2

echo ""
echo "Test 6: Rapid fire (100 items, no delay)"
echo "----------------------------------------------"
for i in {1..100}; do
    echo "Rapid $i" | pbcopy
done
echo "✓ Copied 100 items rapidly"
sleep 2

echo ""
echo "Test 7: Special characters and escapes"
echo "----------------------------------------------"
echo "Quotes: \"double\" 'single'" | pbcopy
sleep 0.5
echo "Backslash: \\ and newline: \n tab: \t" | pbcopy
sleep 0.5
echo "SQL: SELECT * FROM users WHERE id='1' OR '1'='1'" | pbcopy
sleep 0.5
echo "✓ Copied special characters"

echo ""
echo "================================"
echo "Stress test complete!"
echo ""
echo "📊 Check the app to verify:"
echo "  - Should show max 25 items (not all 170+)"
echo "  - Search should work"
echo "  - UI should be responsive"
echo "  - No crashes or freezes"
echo ""
echo "📝 Check logs:"
echo "  tail -100 /tmp/clipboard_debug.log"
