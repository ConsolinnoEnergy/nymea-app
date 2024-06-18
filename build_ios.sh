#!/bin/bash

set -e
export ROOT_DIR=$(pwd)
cd ..
wget https://download.qt.io/official_releases/qt/5.15/5.15.14/single/qt-everywhere-opensource-src-5.15.14.tar.xz
tar xfv qt-everywhere-opensource-src-5.15.14.tar.xz
cd qt-everywhere-src-5.15.14
# Quick and dirty patch. Should be done using a patch file, when things are running.
# See https://decovar.dev/blog/2018/02/17/build-qt-statically/
sed -i'' -e 's/unary_function/__unary_function/' qtmultimedia/src/plugins/avfoundation/camera/avfcamerautility.mm
cd ..
git clone https://github.com/crystalidea/qt-build-tools.git
rsync -av qt-build-tools/5.15.14/qtbase/ qt-everywhere-src-5.15.14/qtbase
cd qt-everywhere-src-5.15.14
./configure QMAKE_APPLE_DEVICE_ARCHS="arm64" -opensource -confirm-license -nomake examples -nomake tests -xplatform macx-ios-clang -release -no-openssl -securetransport -prefix /Users/runner/work/consolinno-hems-app-builder/QtBuild
make -j$(sysctl -n hw.ncpu)
make install

cd $ROOT_DIR


mkdir -p ./build/ios
cd ./build/ios
export BUILD_DIR=$(pwd)
export QT_ROOT=/Users/runner/work/consolinno-hems-app-builder/QtBuild
# Preven/Users/runner/work/consolinno-hems-app-builder/QtBuild
sed -i -e 's/QMAKE_MAC_XCODE_SETTINGS += IOS_DEVELOPMENT_TEAM//g' ../../nymea-app/nymea-app/nymea-app.pro
# Patch mkspec to NOT default to legacy build system of xcode
# See https://stackoverflow.com/questions/69049200/qt-5-12-for-ios-build-system
sed -i -e 's|<key>BuildSystemType</key>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
sed -i -e 's|<string>Original</string>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
$QT_ROOT/bin/qmake ${ROOT_DIR}/nymea-app/ -spec macx-ios-clang  \
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
