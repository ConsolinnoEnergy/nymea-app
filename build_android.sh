#!/bin/bash
set -e
export ROOT_DIR=$(pwd)

cd .. 
wget https://github.com/ConsolinnoEnergy/qt5-builder/releases/download/v5.15.16-android-build2/Qt-5.15-16-android.tar.gz
mkdir qt-5.15.16
tar -xzf Qt-5.15-16-android.tar.gz -C qt-5.15.16
cd $ROOT_DIR

mkdir -p ./build/android

export QT_ROOT=$(pwd)/../qt-5.15.16
export PATH=$QT_ROOT/bin:$PATH

cd ./build/android

export BUILD_DIR=$(pwd)
if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
    export ANDROID_NDK_ROOT=/usr/local/lib/android/sdk/ndk-bundle
fi
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
    ADEPQT=androiddeployqt
else
    QMAKE=${QT_ROOT}/bin/qmake
    ADEPQT=${QT_ROOT}/bin/androiddeployqt
fi

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
    MAKE_BIN=make
else
    MAKE_BIN=$ANDROID_NDK_ROOT/prebuilt/linux-x86_64/bin/make
fi

export VERSION=$(cat ${ROOT_DIR}/nymea-app-consolinno-overlay/version.txt | head -n1 | sed 's/\./-/g')

echo "Build tools:"
echo "qmake: $QMAKE"
echo "make: $MAKE_BIN"
echo "androiddeployqt: $ADEPQT"
echo "Android NDK root: $ANDROID_NDK_ROOT"

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
-spec android-clang \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay \
'ANDROID_ABIS=armeabi-v7a arm64-v8a x86_64'

make -j$(nproc) qmake_all 
make lrelease
make -j$(nproc)
make -j$(nproc) INSTALL_ROOT=${BUILD_DIR}/nymea-app/android-build install

SETTINGS_JSON=$WHITELABEL_TARGET

if [ "$WHITELABEL_TARGET" == "Consolinno-HEMS" ]; then
  # for consolinno a different application name is used.
  SETTINGS_JSON="consolinno-energy"
fi

if [[ -z "${SELFSIGN}" ]]; then
    # Sign and build .aab file
    $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-$SETTINGS_JSON-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-34 \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --gradle --aab \
    --jarsigner \
    --sign ${KEYSTORE_PATH} ${SIGNING_KEY_ALIAS} \
    --storepass ${SIGNING_STORE_PASSWORD} \
    --keypass ${SIGNING_KEY_PASSWORD}
    
    # Building unsigned apk and signing it manuallly to use --v2-signing scheme
     $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-$SETTINGS_JSON-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-34 \
    --release \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --gradle
    
    /usr/local/lib/android/sdk//build-tools/34.0.0/apksigner sign \
    --ks-pass  pass:${SIGNING_STORE_PASSWORD} \
    --ks ${KEYSTORE_PATH} \
    --ks-key-alias ${SIGNING_KEY_ALIAS} \
    --key-pass pass:${SIGNING_KEY_PASSWORD} \
    --v2-signing-enabled  \
    -v \
    --out $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/${SETTINGS_JSON}-${VERSION}-signed.apk \
    $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/android-build-release-unsigned.apk

    mv $BUILD_DIR/nymea-app/android-build//build/outputs/bundle/release/android-build-release.aab $BUILD_DIR/nymea-app/android-build//build/outputs/bundle/release/${SETTINGS_JSON}-${VERSION}-release.aab

else
    # SELFSIGN env is defined -> build .apk and sign with new keypair
    $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-$SETTINGS_JSON-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-34 \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --release \
    --gradle

    # Creating keypair 
    openssl req -x509 -days 9125 -newkey rsa:1024 -nodes -keyout key.pem -out certificate_x509.pem \
            -subj "/C=DE/ST=Bavaria/L=Regensburg/O=Consolinno energy GmbH/CN=consolinno.de" 
    openssl pkcs8 -topk8 -outform DER -in key.pem -inform PEM -out key.pk8 -nocrypt

    $APKSIGNER_BIN sign \
    --v2-signing-enabled  \
    --key $BUILD_DIR/key.pk8 --cert $BUILD_DIR/certificate_x509.pem \
    -v \
    --out $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/${SETTINGS_JSON}-${VERSION}-selfsigned.apk \
    $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/android-build-release-unsigned.apk

fi

mv $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/android-build-release-unsigned.apk $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/${SETTINGS_JSON}-release-unsigned.apk

