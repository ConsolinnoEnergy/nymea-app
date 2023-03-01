#!/bin/bash
export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/21.4.7075529 
export NOSIGN=1
export QT_ROOT=$HOME/Qt/5.15.2/
function cleanup()
{
    git restore ./
}

trap cleanup EXIT
cd ..
./patch_test_version.sh
./build_android.sh
cd -

