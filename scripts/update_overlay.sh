#!/usr/bin/env bash

OLD="./configuration-files/$WHITELABEL_TARGET/overlay.qrc"
NEW="./nymea-app-consolinno-overlay/overlay.qrc"

if [[ ! -f "$OLD" || ! -f "$NEW" ]]; then
    echo "One or both files do not exist. Please check the paths."
    echo "OLD: $OLD"
    echo "NEW: $NEW"
    exit 1
fi

NEW_BLOCK=$(sed -n '/<qresource prefix="\/ui">/,/<\/qresource>/p' "$NEW" | sed '1d;$d')
OLD_BLOCK=$(sed -n '/<qresource prefix="\/ui">/,/<\/qresource>/p' "$OLD" | sed '1d;$d')

MISSING_LINES=$(printf '%s\n' "$NEW_BLOCK" | grep -Fxv -f <(printf '%s\n' "$OLD_BLOCK"))

if [[ -z "$MISSING_LINES" ]]; then
    echo "No new lines to insert found."
    exit 0
fi

echo "Missing lines found:"
echo "$MISSING_LINES"

if mktemp -u >/dev/null 2>&1; then
    TMP_MISSING=$(mktemp)
else
    TMP_MISSING=$(mktemp -t missing_lines)
fi

printf '%s\n' "$MISSING_LINES" > "$TMP_MISSING"

if sed --version >/dev/null 2>&1; then
    SED_INPLACE=(-i)
else
    SED_INPLACE=(-i '')
fi

sed "${SED_INPLACE[@]}" '/<qresource prefix="\/ui">/r '"$TMP_MISSING" "$OLD"

rm "$TMP_MISSING"

echo "New lines inserted."