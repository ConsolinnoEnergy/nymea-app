#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/ios
cd ./build/ios
export BUILD_DIR=$(pwd)
export QT_ROOT=$(which qmake | sed 's|/bin/qmake||g')
# Patch mkspec to NOT default to legacy build system of xcode
# See https://stackoverflow.com/questions/69049200/qt-5-12-for-ios-build-system
sed -i -e 's|<key>BuildSystemType</key>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
sed -i -e 's|<string>Original</string>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
#qmake ${ROOT_DIR}/nymea-app/ CONFIG+=qtquickcompiler OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay   PKG_CONFIG=/usr/bin/pkg-config
qmake ${ROOT_DIR}/nymea-app/ -spec macx-ios-clang CONFIG+=debug CONFIG+=iphoneos QMAKE_MAC_XCODE_SETTINGS+=qteam qteam.name=Consolinno qteam.value=<your-team-id>
 CONFIG+=device CONFIG+=qml_debug QMAKE_TARGET_BUNDLE_PREFIX+=hems.consolinno.energy QMAKE_BUNDLE+=consolinno-energy OVERLAY_PATH=${ROOT_DIR}/nymea-app-conso
make -j $(sysctl -n hw.physicalcpu)

