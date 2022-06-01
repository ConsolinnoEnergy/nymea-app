##!/bin/bash
#set -e
#mkdir -p ./build
#export ROOT_DIR=$(pwd)
#cd build 
#export BUILD_DIR=$(pwd)
#
#QT_ROOT=/home/lheizinger/Qt/5.15.2/
#export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/21.3.6528147
#export ANDROID_SDK_ROOT=$HOME/Android/Sdk/
#
#$QT_ROOT/android/bin/qmake ${ROOT_DIR}/nymea-app/ -spec android-clang CONFIG+=qtquickcompiler OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay PKG_CONFIG=/usr/bin/pkg-config 'ANDROID_ABIS=armeabi-v7a arm64-v8a'
#make -j$(nproc)
#make -j$(nproc) apk_install_target
##
#$QT_ROOT/android/bin/androiddeployqt --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json --output $BUILD_DIR/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle
###$QT_ROOT/android/bin/androiddeployqt --input $(pwd)/nymea-app/android-consolinno-energy-deployment-settings.json --output $(pwd)/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle --aab --jarsigner --sign '******' --storepass '******'
#
#
#!/bin/bash
set -e
mkdir -p ./build
export ROOT_DIR=$(pwd)
cd build
export BUILD_DIR=$(pwd)

#export ANDROID_NDK_ROOT=/usr/local/lib/android/sdk/ndk/21.4.7075529/
#$HOME/Android/Sdk/ndk/21.3.6528147
#export ANDROID_SDK_ROOT=$HOME/Android/Sdk/

qmake ${ROOT_DIR}/nymea-app/ -spec android-clang CONFIG+=qtquickcompiler OVERLAY_PATH=${ROOT_DIR}/nymea-app-consolinno-overlay PKG_CONFIG=/usr/bin/pkg-config 'ANDROID_ABIS=armeabi-v7a arm64-v8a'
make -j$(nproc)
make -j$(nproc) apk_install_target
#
androiddeployqt --input $BUILD_DIR/nymea-app/android-consolinno-energy-deployment-settings.json --output $BUILD_DIR/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle
##$QT_ROOT/android/bin/androiddeployqt --input $(pwd)/nymea-app/android-consolinno-energy-deployment-settings.json --output $(pwd)/nymea-app/android-build --android-platform android-32 --jdk /usr/lib/jvm/java-8-openjdk-amd64 --gradle --aab --jarsigner --sign '******' --storepass '******'
