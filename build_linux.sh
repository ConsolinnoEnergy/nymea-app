#!/bin/bash
# Example usage to start and build Consolinno-HEMS app in german:
# QT_ROOT=<PATH_TO_QT>/Qt/5.15.2 ./build_linux.sh Consolinno-HEMS run de_DE

set -e

export WHITELABEL_TARGET=$1

if [ ! -d "./configuration-files/$WHITELABEL_TARGET" ]; then
    echo "Whitelabel target $WHITELABEL_TARGET does not exist. Available options are:"
    ls -1 ./configuration-files
    exit 1
fi

cd nymea-app-consolinno-overlay
git clean -f -d -x
cd ..

./distribute_assets.sh

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
if [[ "$2" == "run" ]]; then
    echo "Running nymea-app"
    # Should be fixed when output binary is called $WHITELABEL_TARGET
    if [ $WHITELABEL_TARGET == "Consolinno-HEMS" ]; then
        LANGUAGE=$3 ${BUILD_DIR}/nymea-app/linux-build/usr/bin/consolinno-energy
    elif [ $WHITELABEL_TARGET == "Q.HOME-CONTROL" ]; then
        LANGUAGE=$3 ${BUILD_DIR}/nymea-app/linux-build/usr/bin/Q.HOME-CONTROL
    elif [ $WHITELABEL_TARGET == "Zewo-Dynamics" ]; then
        LANGUAGE=$3 ${BUILD_DIR}/nymea-app/linux-build/usr/bin/consolinno-energy
    fi
fi
