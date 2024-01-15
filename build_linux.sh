#!/bin/bash
# Example usage to start app in german: 
# QT_ROOT=<PATH_TO_QT>/Qt/5.15.2 ./build_linux.sh run de_DE
set -e

export ROOT_DIR=$(pwd)
mkdir -p ./build/linux
cd ./build/linux
export BUILD_DIR=$(pwd)
if [[ -z "${QT_ROOT}" ]]; then
    QMAKE=qmake
else
    QMAKE=${QT_ROOT}/gcc_64/bin/qmake
fi

MAKE_BIN=make
echo "Build tools:"
echo "qmake: $QMAKE"
$QMAKE -v
echo "make: $MAKE_BIN"

$QMAKE \
${ROOT_DIR}/nymea-app/nymea-app.pro \
OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay

make -j$(nproc) qmake_all
make lrelease
make -j$(nproc)
make -j$(nproc) INSTALL_ROOT=${BUILD_DIR}/nymea-app/linux-build install

# If run in args then run the app
if [[ "$1" == "run" ]]; then
    echo "Running nymea-app"
    LANGUAGE=$2 ${BUILD_DIR}/nymea-app/linux-build/usr/bin/consolinno-energy
fi

