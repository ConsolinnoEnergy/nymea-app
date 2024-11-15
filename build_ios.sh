#!/bin/bash

# TODO: Maybe move variables into github secrets/variables
CURRENT_APP_NAME=$WHITELABEL_TARGET
if [ "$WHITELABEL_TARGET" == "Q.HOME-CONTROL" ]; then
  PROVISIONING_ID=$PROVISIONING_PROFILE_ID_QCELLS
  TEAM_ID="6F8276DF5B"
  CURRENT_BUNDLE_PREFIX="de.qcells"
  CURRENT_QMAKE_BUNDLE="qhomecontrol"
else
  PROVISIONING_ID=$PROVISIONING_PROFILE_ID_CONSOLINNO
  TEAM_ID="J757FFDWU9"
  CURRENT_BUNDLE_PREFIX="hems.consolinno"
  CURRENT_QMAKE_BUNDLE="energy"
  CURRENT_APP_NAME="consolinno-energy"
fi

set -e
export ROOT_DIR=$(pwd)
cd .. 
wget https://github.com/ConsolinnoEnergy/qt5-builder/releases/download/v5.15.14-build1/Qt-5.15-14-macos-xcode-15.0.1.tar.gz
mkdir qt-5.15.14
tar -xzf Qt-5.15-14-macos-xcode-15.0.1.tar.gz -C qt-5.15.14
cd $ROOT_DIR


mkdir -p ./build/ios
cd ./build/ios
export BUILD_DIR=$(pwd)
export QT_ROOT=/Users/runner/work/consolinno-hems-app-builder/qt-5.15.14
export PATH=$QT_ROOT/bin:$PATH
# Preven/Users/runner/work/consolinno-hems-app-builder/QtBuild
sed -i -e 's/QMAKE_MAC_XCODE_SETTINGS += IOS_DEVELOPMENT_TEAM//g' ../../nymea-app/nymea-app/nymea-app.pro
# Patch mkspec to NOT default to legacy build system of xcode
# See https://stackoverflow.com/questions/69049200/qt-5-12-for-ios-build-system
sed -i -e 's|<key>BuildSystemType</key>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
sed -i -e 's|<string>Original</string>||g' ${QT_ROOT}/mkspecs/macx-xcode/WorkspaceSettings.xcsettings
$QT_ROOT/bin/qmake ${ROOT_DIR}/nymea-app/ -spec macx-ios-clang  \
CONFIG+=iphoneos CONFIG+=device  CONFIG+=qml_debug CONFIG+=release \
QMAKE_MAC_XCODE_SETTINGS=qteam qteam.name="DEVELOPMENT_TEAM" qteam.value=$TEAM_ID \
QMAKE_MAC_XCODE_SETTINGS+=qprofile qprofile.name=PROVISIONING_PROFILE_SPECIFIER qprofile.value=$PROVISIONING_ID \
QMAKE_XCODE_CODE_SIGN_IDENTITY=\""iPhone Distribution\"" \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay \
QMAKE_TARGET_BUNDLE_PREFIX+=$CURRENT_BUNDLE_PREFIX QMAKE_BUNDLE+=$CURRENT_QMAKE_BUNDLE

make qmake_all
set +e
make -j $(sysctl -n hw.physicalcpu)
# First build fails with "BUILD SUCCEEDED" but misses a file. Second make call should really succeed. Not sure what's the problem here.
# Edit: Now it seems to fail. Thus set +e above
rm /Users/runner/work/consolinno-hems-app-builder/consolinno-hems-app-builder/build/ios/nymea-app/$CURRENT_APP_NAME.build/Release-iphoneos/$CURRENT_APP_NAME.build/LaunchScreen.storyboardc
set -e
make -j $(sysctl -n hw.physicalcpu)


mkdir ./Payload
cp -R "${BUILD_DIR}/nymea-app/Release-iphoneos/$CURRENT_APP_NAME.app" ./Payload
zip -qyr $CURRENT_APP_NAME.ipa ./Payload
# rm -r ./Payload
