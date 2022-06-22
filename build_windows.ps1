$ROOT_DIR=$PWD
mkdir -p build\windows
cd build\windows
$BUILD_DIR=$PWD

qmake "$ROOT_DIR\nymea-app" OVERLAY_PATH="$ROOT_DIR\nymea-app-consolinno-overlay" -spec win32-msvc
nmake qmake_all
nmake lrelease
nmake
