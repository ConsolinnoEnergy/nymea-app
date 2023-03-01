#!/bin/bash
./patch_test_version.sh
#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/android
cd ./build/android
export BUILD_DIR=$(pwd)
export ANDROID_NDK_ROOT=/usr/local/lib/android/sdk/ndk-bundle
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
    ADEPQT=androiddeployqt
else
    QMAKE=${QT_ROOT}/android/bin/qmake
    ADEPQT=${QT_ROOT}/android/bin/androiddeployqt
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

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
-spec android-clang \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay \
'ANDROID_ABIS=armeabi-v7a arm64-v8a x86_64'

make -j$(nproc) qmake_all 
make lrelease
make -j$(nproc)
make -j$(nproc) INSTALL_ROOT=${BUILD_DIR}/nymea-app/android-build install

if [[ -z "${SELFSIGN}" ]]; then
    # Building unsigned apk and signing it manuallly to use --v2-signing scheme
     $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-32 \
    --release \
    --jdk /usr/lib/jvm/java-8-openjdk-amd64 \
    --gradle

    /usr/local/lib/android/sdk//build-tools/32.0.0/apksigner sign \
    --ks-pass  pass:${SIGNING_STORE_PASSWORD} \
    --ks ${KEYSTORE_PATH} \
    --ks-key-alias ${SIGNING_KEY_ALIAS} \
    --key-pass pass:${SIGNING_KEY_PASSWORD} \
    --v2-signing-enabled  \
    -v \
    --out $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/consolinno-hems-${VERSION}-signed-testing.apk \
    $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/android-build-release-unsigned.apk
else
    # SELFSIGN env is defined -> build .apk and sign with new keypair
    $ADEPQT \
    --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json \
    --output $BUILD_DIR/nymea-app/android-build \
    --android-platform android-32 \
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
    --out $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/consolinno-hems-${VERSION}-selfsigned-testing.apk \
    $BUILD_DIR/nymea-app/android-build//build/outputs/apk/release/android-build-release-unsigned.apk
fi
 
