APPLICATION_NAME=consolinno-energy
ORGANISATION_NAME=consolinno

PACKAGE_URN=hems.consolinno.energy
PACKAGE_NAME=consolinno-energy

IOS_BUNDLE_PREFIX=consolinno.hems
IOS_BUNDLE_NAME=energy
IOS_DEVELOPMENT_TEAM.name=Consolinno Energy GmbH
IOS_DEVELOPMENT_TEAM.value=J757FFDWU9

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

