#!/bin/bash
export ANDROID_HOME=$HOME/Android/Sdk/
export APKSIGNER_BIN=$HOME/Android/Sdk/build-tools/32.0.0/apksigner
export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/21.4.7075529 
export SELFSIGN=1
export QT_ROOT=$HOME/Qt/5.15.2/
function cleanup()
{
    echo "Clean up: Reverting testing patch..."
    cd nymea-app && git restore ./ && cd .. && cd nymea-app-consolinno-overlay && git restore ./ && cd ..
}
trap cleanup EXIT
cd ..
./build_android_testpatch.sh

