#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/ios
cd ./build/ios
export BUILD_DIR=$(pwd)
export QT_ROOT=$(which qmake | sed 's|/bin/qmake||g')
# Prevent nymea-app from overwriting team info
sed -i -e 's/QMAKE_MAC_XCODE_SETTINGS += IOS_DEVELOPMENT_TEAM//g' ../../nymea-app/nymea-app/nymea-app.pro
# Patch mkspec to NOT default to legacy build system of xcode
# See https://stackoverflow.com/questions/69049200/qt-5-12-for-ios-build-system
sed -i -e 's|<key>BuildSystemType</key>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
sed -i -e 's|<string>Original</string>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
qmake ${ROOT_DIR}/nymea-app/ -spec macx-ios-clang  \
CONFIG+=iphoneos CONFIG+=device  CONFIG+=qml_debug CONFIG+=release \
QMAKE_MAC_XCODE_SETTINGS=qteam qteam.name="DEVELOPMENT_TEAM" qteam.value=J757FFDWU9  \
QMAKE_MAC_XCODE_SETTINGS+=qprofile qprofile.name=PROVISIONING_PROFILE_SPECIFIER qprofile.value=beb37b6b-b1a8-4a7c-8e5b-112c5c8389c9 \
QMAKE_XCODE_CODE_SIGN_IDENTITY=\""iPhone Distribution\"" \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay \
QMAKE_TARGET_BUNDLE_PREFIX+=hems.consolinno QMAKE_BUNDLE+=energy

make qmake_all
set +e 
make -j $(sysctl -n hw.physicalcpu) 
# First build fails with "BUILD SUCCEEDED" but misses a file. Second make call should really succeed. Not sure what's the problem here. 
# Edit: Now it seems to fail. Thus set +e above  
rm /Users/runner/work/consolinno-hems-app-builder/consolinno-hems-app-builder/build/ios/nymea-app/consolinno-energy.build/Release-iphoneos/consolinno-energy.build/LaunchScreen.storyboardc
set -e 
make -j $(sysctl -n hw.physicalcpu)


mkdir ./Payload
cp -R "${BUILD_DIR}/nymea-app/Release-iphoneos/consolinno-energy.app" ./Payload
zip -qyr consolinno-hems.ipa ./Payload
rm -r ./Payload
