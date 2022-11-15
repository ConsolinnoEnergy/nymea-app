#!/bin/bash
set -e
sudo apt install -y libavahi-common-dev  libavahi-client-dev

export ROOT_DIR=$(pwd)
mkdir -p ./build/appimage
cd ./build/appimage
export BUILD_DIR=$(pwd)
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
else
    QMAKE=${QT_ROOT}/gcc_64/bin/qmake
fi

MAKE_BIN=make
LDEPLOYQT=${ROOT_DIR}/linuxdeployqt-*-x86_64.AppImage

echo "Build tools:"
echo "qmake: $QMAKE"
echo "make: $MAKE_BIN"
echo "linuxdeployqt: $LDEPLOYQT"

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay

make -j$(nproc) qmake_all
make lrelease
make -j$(nproc)
make -j$(nproc) INSTALL_ROOT=${BUILD_DIR}/nymea-app/linux-build install
export VERSION=$(cat ${ROOT_DIR}/nymea-app-consolinno-overlay/version.txt | head -n1 | sed 's/\./-/g')
cp ${ROOT_DIR}/nymea-app-consolinno-overlay/packaging/appimage/consolinno-energy.desktop ${ROOT_DIR}/build/appimage/nymea-app/linux-build/usr/share/applications/consolinno-energy.desktop
$LDEPLOYQT ${ROOT_DIR}/build/appimage/nymea-app/linux-build/usr/share/applications/consolinno-energy.desktop  -appimage -qmldir=${ROOT_DIR}/nymea-app -qmldir=${ROOT_DIR}/nymea-app-consolinno-overlay

