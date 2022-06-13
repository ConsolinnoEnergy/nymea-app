#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/android
cd ./build/android
export BUILD_DIR=$(pwd)

if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
    ADEPQT=androiddeployqt
else
    QMAKE=${QT_ROOT}/android/bin/qmake
    ADEPQT=${QT_ROOT}/android/bin/androiddeployqt
fi

$QMAKE \
${ROOT_DIR}/nymea-app/ \
-spec android-clang \
CONFIG+=qtquickcompiler \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay \
PKG_CONFIG=/usr/bin/pkg-config \
'ANDROID_ABIS=armeabi-v7a arm64-v8a'

make -j$(nproc)
make -j$(nproc) apk_install_target


if [[ -z "${NOSIGN}" ]]; then
    # Sign and build .aab file
    $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-32 \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --gradle --aab \
    --jarsigner \
    --sign ${KEYSTORE_PATH} ${SIGNING_KEY_ALIAS} \
    --storepass '${SIGNING_STORE_PASSWORD}' \
    --keypass '${SIGNING_KEY_PASSWORD}'
else
    # NOSIGN env is defined -> build unsigned .apk
    $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-32 \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --gradle
fi

