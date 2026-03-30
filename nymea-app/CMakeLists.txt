set(NYMEA_APP_SOURCES
    main.cpp
    configuredhostsmodel.cpp
    dashboard/dashboarditem.cpp
    dashboard/dashboardmodel.cpp
    mouseobserver.cpp
    nfchelper.cpp
    nfcthingactionwriter.cpp
    platformintegration/platformpermissions.cpp
    stylecontroller.cpp
    pushnotifications.cpp
    platformhelper.cpp
    platformintegration/generic/screenhelper.cpp
    utils/privacypolicyhelper.cpp
    utils/qhashqml.cpp
)

set(NYMEA_APP_HEADERS
    configuredhostsmodel.h
    dashboard/dashboarditem.h
    dashboard/dashboardmodel.h
    mouseobserver.h
    nfchelper.h
    nfcthingactionwriter.h
    platformintegration/generic/screenhelper.h
    platformintegration/platformpermissions.h
    stylecontroller.h
    pushnotifications.h
    platformhelper.h
    ruletemplates/messages.h
    utils/privacypolicyhelper.h
    utils/qhashqml.h
)

if(UNIX AND NOT APPLE AND NOT ANDROID)
    list(APPEND NYMEA_APP_SOURCES
        platformintegration/generic/platformhelpergeneric.cpp
    )
    list(APPEND NYMEA_APP_HEADERS
        platformintegration/generic/platformhelpergeneric.h
    )
endif()

if(ANDROID)
    list(APPEND NYMEA_APP_SOURCES
        platformintegration/android/platformhelperandroid.cpp
        platformintegration/android/platformpermissionsandroid.cpp
    )
    list(APPEND NYMEA_APP_HEADERS
        platformintegration/android/platformhelperandroid.h
        platformintegration/android/platformpermissionsandroid.h
    )
endif()

if(IOS)
    list(APPEND NYMEA_APP_SOURCES
        platformintegration/ios/platformhelperios.cpp
        platformintegration/ios/platformpermissionsios.cpp
        platformintegration/ios/platformhelperios.mm
        platformintegration/ios/pushnotifications.mm
        platformintegration/ios/platformpermissionsios.mm
    )
    list(APPEND NYMEA_APP_HEADERS
        platformintegration/ios/platformhelperios.h
        platformintegration/ios/platformpermissionsios.h
    )
endif()

set(NYMEA_APP_RESOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/resources.qrc
    ${CMAKE_CURRENT_SOURCE_DIR}/ruletemplates.qrc
    ${CMAKE_CURRENT_SOURCE_DIR}/images.qrc
)

# Compile translations (.ts -> .qm) into the source translations/ directory
# so that translations.qrc (which references that directory) picks them up.
file(GLOB NYMEA_TS_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/translations/*.ts")
set(ALL_TS_FILES ${NYMEA_TS_FILES})

if(NYMEA_OVERLAY_PATH AND EXISTS "${NYMEA_OVERLAY_PATH}/translations")
    file(GLOB OVERLAY_TS_FILES CONFIGURE_DEPENDS "${NYMEA_OVERLAY_PATH}/translations/*.ts")
    list(APPEND ALL_TS_FILES ${OVERLAY_TS_FILES})
endif()

# Run lrelease for each .ts file, output .qm into the nymea-app translations/ directory
# so that translations.qrc (which references that directory) picks them all up.
set(NYMEA_TRANSLATIONS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/translations")
set(ALL_QM_FILES "")
foreach(_ts_file ${ALL_TS_FILES})
    get_filename_component(_ts_filename "${_ts_file}" NAME)
    string(REGEX REPLACE "\\.ts$" ".qm" _qm_filename "${_ts_filename}")
    set(_qm_file "${NYMEA_TRANSLATIONS_DIR}/${_qm_filename}")
    add_custom_command(
        OUTPUT "${_qm_file}"
        COMMAND Qt6::lrelease "${_ts_file}" -qm "${_qm_file}"
        DEPENDS "${_ts_file}"
        COMMENT "Compiling ${_ts_filename}"
        VERBATIM
    )
    list(APPEND ALL_QM_FILES "${_qm_file}")
endforeach()

add_custom_target(nymea-app-translations ALL DEPENDS ${ALL_QM_FILES})

list(APPEND NYMEA_APP_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/translations.qrc)

if(NYMEA_OVERLAY_PATH)
    # Load overlay configuration (APPLICATION_NAME, ORGANISATION_NAME, etc.)
    if(EXISTS "${NYMEA_OVERLAY_PATH}/overlay-config.cmake")
        include("${NYMEA_OVERLAY_PATH}/overlay-config.cmake")
    endif()

    # Overlay QRC replaces the default styles.qrc
    list(APPEND NYMEA_APP_RESOURCES "${NYMEA_OVERLAY_PATH}/overlay.qrc")

    # Overlay C++ sources (src/ directory)
    if(EXISTS "${NYMEA_OVERLAY_PATH}/src")
        file(GLOB_RECURSE OVERLAY_SOURCES CONFIGURE_DEPENDS "${NYMEA_OVERLAY_PATH}/src/*.cpp")
        file(GLOB_RECURSE OVERLAY_HEADERS CONFIGURE_DEPENDS "${NYMEA_OVERLAY_PATH}/src/*.h")
        list(APPEND NYMEA_APP_SOURCES ${OVERLAY_SOURCES})
        list(APPEND NYMEA_APP_HEADERS ${OVERLAY_HEADERS})
    endif()
else()
    list(APPEND NYMEA_APP_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/styles.qrc)
endif()

if(NYMEA_USE_MATERIAL_ICONS)
    list(APPEND NYMEA_APP_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/ui/icons/material/icons.qrc)
else()
    list(APPEND NYMEA_APP_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/ui/icons/suru/icons.qrc)
endif()

qt_add_executable(nymea-app
    MANUAL_FINALIZATION
    ${NYMEA_APP_SOURCES}
    ${NYMEA_APP_HEADERS}
    ${NYMEA_APP_RESOURCES}
)

# Allow whitelabel-specific binary name (e.g. "consolinno-energy" instead of "nymea-app")
if(NYMEA_APP_BINARY_NAME)
    set_target_properties(nymea-app PROPERTIES OUTPUT_NAME "${NYMEA_APP_BINARY_NAME}")
endif()

target_include_directories(nymea-app
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/libnymea-app
        ${CMAKE_SOURCE_DIR}/experiences/airconditioning
        ${CMAKE_SOURCE_DIR}/experiences/evdash
        ${CMAKE_BINARY_DIR}
)

if(NYMEA_OVERLAY_PATH)
    target_include_directories(nymea-app PRIVATE "${NYMEA_OVERLAY_PATH}/src")
    target_compile_definitions(nymea-app PRIVATE
        OVERLAY_PATH="${NYMEA_OVERLAY_PATH}"
        OVERLAY_QMLTYPES="${NYMEA_OVERLAY_PATH}/src/qmltypes.h"
    )
endif()

target_link_libraries(nymea-app
    PRIVATE
        nymea-app-core
        nymea-app-airconditioning
        nymea-app-evdash
        Qt6::Gui
        Qt6::Network
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Svg
        Qt6::WebSockets
        Qt6::Bluetooth
        Qt6::Charts
        Qt6::Nfc
)

if(TARGET Qt6::WebView)
    target_link_libraries(nymea-app PRIVATE Qt6::WebView)
    target_compile_definitions(nymea-app PRIVATE HAVE_WEBVIEW)
endif()

find_package(Qt6 COMPONENTS GuiPrivate QUIET)
if(TARGET Qt6::GuiPrivate)
    target_link_libraries(nymea-app PRIVATE Qt6::GuiPrivate)
else()
    message(WARNING "Qt6::GuiPrivate not found; continuing without private GUI APIs.")
endif()

if(UNIX AND NOT APPLE AND NYMEA_ENABLE_ZEROCONF)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(AVAHI REQUIRED IMPORTED_TARGET avahi-client avahi-common)
    target_link_libraries(nymea-app PRIVATE PkgConfig::AVAHI)
endif()

if(WIN32)
    target_compile_definitions(nymea-app PRIVATE NOMINMAX)
endif()

if(ANDROID)
    if(DEFINED NYMEA_ANDROID_PACKAGE_SOURCE_DIR)
        set_property(TARGET nymea-app PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR "${NYMEA_ANDROID_PACKAGE_SOURCE_DIR}")
    endif()

    set_property(TARGET nymea-app PROPERTY QT_ANDROID_MIN_SDK_VERSION 23)
    set_property(TARGET nymea-app PROPERTY QT_ANDROID_TARGET_SDK_VERSION 36)

    if(NYMEA_ENABLE_FIREBASE)
        target_compile_definitions(nymea-app PRIVATE WITH_FIREBASE)
        target_include_directories(nymea-app PRIVATE ${CMAKE_SOURCE_DIR}/3rdParty/android/firebase_cpp_sdk/include)

        if(CMAKE_ANDROID_ARCH_ABI)
            set(_firebase_lib_dir "${CMAKE_SOURCE_DIR}/3rdParty/android/firebase_cpp_sdk/libs/android/${CMAKE_ANDROID_ARCH_ABI}/c++")
            target_link_libraries(nymea-app PRIVATE
                "${_firebase_lib_dir}/libfirebase_messaging.a"
                "${_firebase_lib_dir}/libfirebase_app.a"
            )
        else()
            message(WARNING "CMAKE_ANDROID_ARCH_ABI is not defined; Firebase static libraries could not be linked.")
        endif()
    else()
        message(STATUS "Firebase support disabled via NYMEA_ENABLE_FIREBASE option.")
    endif()
endif()

if(IOS)
    target_link_libraries(nymea-app PRIVATE
        "-framework CoreLocation"
        "-framework CoreBluetooth"
        "-framework CoreNFC"
    )

    set(_nymea_ios_plist "${CMAKE_CURRENT_BINARY_DIR}/ios/Info.plist")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/ios")
    configure_file(
        ${CMAKE_SOURCE_DIR}/packaging/ios/Info.plist.cmake.in
        ${_nymea_ios_plist}
        @ONLY
    )

    set_target_properties(nymea-app PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${_nymea_ios_plist}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${NYMEA_IOS_BUNDLE_IDENTIFIER}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${APP_REVISION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${APP_VERSION}"
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_SOURCE_DIR}/packaging/ios/app.entitlements"
    )

    if(NYMEA_IOS_TEAM_ID)
        set_target_properties(nymea-app PROPERTIES
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${NYMEA_IOS_TEAM_ID}"
        )
    endif()
    if(NYMEA_IOS_PROVISIONING_PROFILE)
        set_target_properties(nymea-app PROPERTIES
            XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Manual"
            XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${NYMEA_IOS_PROVISIONING_PROFILE}"
        )
    endif()

    target_link_options(nymea-app PRIVATE "-ObjC")

    set_property(TARGET nymea-app APPEND PROPERTY
        QT_IOS_ASSET_CATALOGS "${CMAKE_SOURCE_DIR}/packaging/ios/Assets.xcassets")

    set(_nymea_ios_resources
        ${CMAKE_SOURCE_DIR}/packaging/ios/NymeaLaunchScreen.storyboard
        ${CMAKE_SOURCE_DIR}/packaging/ios/GoogleService-Info.plist
    )
    set_source_files_properties(${_nymea_ios_resources} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources)
    target_sources(nymea-app PRIVATE ${_nymea_ios_resources})

    if(NYMEA_ENABLE_FIREBASE)
        target_compile_definitions(nymea-app PRIVATE WITH_FIREBASE FIREBASE_ANALYTICS_SUPPRESS_WARNING)
        target_include_directories(nymea-app PRIVATE ${CMAKE_SOURCE_DIR}/3rdParty/ios)
        target_link_directories(nymea-app PRIVATE
            ${CMAKE_SOURCE_DIR}/3rdParty/ios/Firebase/FirebaseAnalytics
            ${CMAKE_SOURCE_DIR}/3rdParty/ios/Firebase/FirebaseMessaging
        )
        target_link_libraries(nymea-app PRIVATE
            "-framework FirebaseMessaging"
            "-framework GoogleUtilities"
            "-framework Protobuf"
            "-framework FirebaseCore"
            "-framework FirebaseInstanceID"
            "-framework FirebaseInstallations"
            "-framework PromisesObjC"
        )
    endif()
endif()

qt_finalize_executable(nymea-app)
