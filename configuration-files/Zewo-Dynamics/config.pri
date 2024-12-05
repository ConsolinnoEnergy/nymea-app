APPLICATION_NAME=Zewo-Dynamics
ORGANISATION_NAME=zewodynamics

PACKAGE_URN=ems.zewo.dynamics
PACKAGE_NAME=zewo-dynamics

IOS_BUNDLE_PREFIX=ems.zewo
IOS_BUNDLE_NAME=dynamics
IOS_DEVELOPMENT_TEAM.name=ZEWOTHERM Heating GmbH
IOS_DEVELOPMENT_TEAM.value=33XL9DDWVW

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

