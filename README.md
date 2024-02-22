# HEMS App Builder
This repo provides build scripts for the Consolinno HEMS App based on nymea-app. It contains two submodules nymea-app-consolinno-overlay and nymea-app.
The nymea-app project is the main Qt project which contains the source code of the stock nymea app and the Qt build instructions. The nymea-app projects support customization using an overlay, which in this case is provided by nymea-app-consolinno-overlay.

# Build
## CI
The CI can build the app for Android, iOS, Linux (AppImage) and Windows. 

## Development build
The build_linux.sh script can be used to build the app locally. Qt 5.15.2 must be installed on your system to a known path and the QT_ROOT variable needs to be defined accordingly.
Optionally you can define the locale which is used to define the language in the app. Currently only de_DE and en_US is supported.
Example build an run of the app:

    QT_ROOT=/home/username/Qt/5.15.2 ./build_linux.sh run de_DE
