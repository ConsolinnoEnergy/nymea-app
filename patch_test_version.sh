#!/bin/bash
cd nymea-app
find ./ -iname "*.qml" | xargs -L1 python ../patch_accessibility.py --inplace {}
cd nymea-app-consolinno-overlay
find ./ -iname "*.qml" | xargs -L1 python ../patch_accessibility.py --inplace {}
cd ..
