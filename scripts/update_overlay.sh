#!/bin/bash

OLD="./configuration-files/$WHITELABEL_TARGET/overlay.qrc"
NEW="./nymea-app-consolinno-overlay/overlay.qrc"

if [ ! -f "$OLD" ] || [ ! -f "$NEW" ]; then
    echo "One or both files do not exist. Please check the paths."
    echo "OLD: $OLD"
    echo "NEW: $NEW"
    exit 1
fi

NEW_BLOCK=$(sed -n '/<qresource prefix="\/ui">/,/<\/qresource>/p' "$NEW" | sed '1d;$d')

OLD_BLOCK=$(sed -n '/<qresource prefix="\/ui">/,/<\/qresource>/p' "$OLD" | sed '1d;$d')

MISSING_LINES=$(echo "$NEW_BLOCK" | grep -Fxv -f <(echo "$OLD_BLOCK"))

if [ -z "$MISSING_LINES" ]; then
    echo "No new lines to insert found."
    exit 0
fi

echo "Missing lines found:"
echo "$MISSING_LINES"

TMP_MISSING=$(mktemp)
echo "$MISSING_LINES" > "$TMP_MISSING"

sed -i '/<qresource prefix="\/ui">/r '"$TMP_MISSING" "$OLD"

rm "$TMP_MISSING"

echo "New lines inserted."