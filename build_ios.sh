#!/bin/bash
set -e
export ROOT_DIR=$(pwd)
mkdir -p ./build/android
cd ./build/android
export BUILD_DIR=$(pwd)
qmake ${ROOT_DIR}/nymea-app/ CONFIG+=qtquickcompiler OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay -spec macx-xcode  PKG_CONFIG=/usr/bin/pkg-config
make -j$(nproc)

