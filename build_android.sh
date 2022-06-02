#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/android
cd ./build/android
export BUILD_DIR=$(pwd)

qmake ${ROOT_DIR}/nymea-app/ -spec android-clang CONFIG+=qtquickcompiler OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay PKG_CONFIG=/usr/bin/pkg-config 'ANDROID_ABIS=armeabi-v7a arm64-v8a'
make -j$(nproc)
make -j$(nproc) apk_install_target

androiddeployqt --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json --output $BUILD_DIR/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle
##$QT_ROOT/android/bin/androiddeployqt --input $(pwd)/nymea-app/android-consolinno-energy-deployment-settings.json --output $(pwd)/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle --aab --jarsigner --sign '******' --storepass '******'
