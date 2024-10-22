APPLICATION_NAME=Q.HOME-CONTROL
ORGANISATION_NAME=qcells

PACKAGE_URN=com.qhomemanager
PACKAGE_NAME=Q.HOME-CONTROL

IOS_BUNDLE_PREFIX=com
IOS_BUNDLE_NAME=qhomemanager
IOS_DEVELOPMENT_TEAM.name=Hanwha Q CELLS GmbH
IOS_DEVELOPMENT_TEAM.value=6F8276DF5B

VERSION_INFO=$$cat(version.txt)
APP_VERSION=$$member(VERSION_INFO, 0)
APP_REVISION=$$member(VERSION_INFO, 1)

android {
    # Provides version_overlay.txt for Android build instead of nymea-app version.txt
    copydata.commands = $(COPY_DIR) $$PWD/version.txt $$OUT_PWD/version_overlay.txt
    first.depends = $(first) copydata
    export(first.depends)
    export(copydata.commands)
    QMAKE_EXTRA_TARGETS += first copydata
}

