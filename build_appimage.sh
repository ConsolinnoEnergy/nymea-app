#!/bin/bash
set -e
sudo apt install -y libavahi-common-dev  libavahi-client-dev rename

export ROOT_DIR=$(pwd)
mkdir -p ./build/appimage

cp ./scripts/firstRun.sh ./build/appimage

cd ./build/appimage
export BUILD_DIR=$(pwd)
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
else
    QMAKE=${QT_ROOT}/gcc_64/bin/qmake
fi

MAKE_BIN=make
LDEPLOYQT=${ROOT_DIR}/linuxdeployqt-*-x86_64.AppImage
COMMIT_HASH=$(git rev-parse --short "$GITHUB_SHA")
echo "Build tools:"
echo "qmake: $QMAKE"
echo "make: $MAKE_BIN"
echo "linuxdeployqt: $LDEPLOYQT"

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay

SETTINGS_JSON=$WHITELABEL_TARGET

if [ "$WHITELABEL_TARGET" == "Consolinno-HEMS" ]; then
  # for consolinno a different application name is used.
  SETTINGS_JSON="consolinno-energy"
fi

make -j$(nproc) qmake_all
make lrelease
make -j$(nproc)
make -j$(nproc) INSTALL_ROOT=${BUILD_DIR}/nymea-app/linux-build install
export VERSION=$(cat ${ROOT_DIR}/nymea-app-consolinno-overlay/version.txt | head -n1 | sed 's/\./-/g')
mkdir -p ${ROOT_DIR}/build/appimage/nymea-app/linux-build/usr/share/applications/
cp ${ROOT_DIR}/nymea-app-consolinno-overlay/packaging/appimage/$SETTINGS_JSON.desktop ${ROOT_DIR}/build/appimage/nymea-app/linux-build/usr/share/applications/$SETTINGS_JSON.desktop
$LDEPLOYQT ${ROOT_DIR}/build/appimage/nymea-app/linux-build/usr/share/applications/$SETTINGS_JSON.desktop  -appimage -qmldir=${ROOT_DIR}/nymea-app -qmldir=${ROOT_DIR}/nymea-app-consolinno-overlay
rename "s/x86/$COMMIT_HASH-x86/g" build/appimage/${SETTINGS_JSON}-${VERSION}-X86_64.AppImage
