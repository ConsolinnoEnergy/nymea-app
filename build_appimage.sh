#!/bin/bash
set -e
sudo apt install -y libavahi-common-dev libavahi-client-dev libfuse2 rename 

export ROOT_DIR=$(pwd)

cd .. 
wget https://github.com/ConsolinnoEnergy/qt5-builder/releases/download/v5.15.16-linux-build-6/Qt-5.15-16-linux.tar.gz
mkdir qt-5.15.16
tar -xzf Qt-5.15-16-linux.tar.gz -C qt-5.15.16
cd $ROOT_DIR

mkdir -p ./build/appimage

export QT_ROOT=$(pwd)/../qt-5.15.16
export PATH=$QT_ROOT/bin:$PATH

cp ./scripts/firstRun.sh ./build/appimage
 
cd ./build/appimage
export BUILD_DIR=$(pwd)
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
else
    QMAKE=${QT_ROOT}/bin/qmake
fi

MAKE_BIN=make
LDEPLOYQT=${ROOT_DIR}/linuxdeployqt-*-x86_64.AppImage
COMMIT_HASH=$(git rev-parse --short "$GITHUB_SHA")
echo "Build tools:"
echo "qmake: $QMAKE"
echo "make: $MAKE_BIN"
echo "linuxdeployqt: $LDEPLOYQT"
echo "$QMAKE $ROOT_DIR/nymea-app/nymea-app.pro"

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay

SETTINGS_JSON=${WHITELABEL_TARGET}

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
