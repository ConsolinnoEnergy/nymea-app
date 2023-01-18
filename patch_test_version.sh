#!/bin/bash
cd nymea-app
find ./ -iname "*.qml" | xargs -L1 python ../patch_accessibility.py --inplace {}
cd ..
cd nymea-app-consolinno-overlay
find ./ -iname "*.qml" | xargs -L1 python ../patch_accessibility.py --inplace {}
cd ..
