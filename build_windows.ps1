$ROOT_DIR=$PWD
mkdir -p build\windows
cd build\windows
$BUILD_DIR=$PWD

qmake "$ROOT_DIR\nymea-app" OVERLAY_PATH="$ROOT_DIR\nymea-app-consolinno-overlay" -spec win32-msvc
nmake qmake_all
nmake lrelease
nmake
aqt.exe install-tool windows desktop tools_ifw
cp Tools/QtInstallerFramework/4.4/bin/* ../../../Qt/5.15.2/msvc2019_64/bin
nmake wininstaller
