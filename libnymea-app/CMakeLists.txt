set(LIBNYMEA_APP_SOURCES)
file(GLOB_RECURSE LIBNYMEA_APP_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp
)
file(GLOB_RECURSE LIBNYMEA_APP_HEADERS CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.h
)

if(IOS)
    file(GLOB_RECURSE LIBNYMEA_APP_MM_SOURCES CONFIGURE_DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/*.mm
    )
    list(APPEND LIBNYMEA_APP_SOURCES ${LIBNYMEA_APP_MM_SOURCES})
endif()

if(EMSCRIPTEN)
    list(FILTER LIBNYMEA_APP_SOURCES EXCLUDE REGEX ".*/connection/bluetooth[^/]*$")
    list(FILTER LIBNYMEA_APP_SOURCES EXCLUDE REGEX ".*/connection/tcpsockettransport[^/]*$")
    list(FILTER LIBNYMEA_APP_SOURCES EXCLUDE REGEX ".*/connection/discovery/bluetoothservicediscovery[^/]*$")
    list(FILTER LIBNYMEA_APP_SOURCES EXCLUDE REGEX ".*/connection/discovery/upnpdiscovery[^/]*$")
    list(FILTER LIBNYMEA_APP_SOURCES EXCLUDE REGEX ".*/wifisetup/.*")
    list(FILTER LIBNYMEA_APP_HEADERS EXCLUDE REGEX ".*/connection/bluetooth[^/]*$")
    list(FILTER LIBNYMEA_APP_HEADERS EXCLUDE REGEX ".*/connection/tcpsockettransport[^/]*$")
    list(FILTER LIBNYMEA_APP_HEADERS EXCLUDE REGEX ".*/connection/discovery/bluetoothservicediscovery[^/]*$")
    list(FILTER LIBNYMEA_APP_HEADERS EXCLUDE REGEX ".*/connection/discovery/upnpdiscovery[^/]*$")
    list(FILTER LIBNYMEA_APP_HEADERS EXCLUDE REGEX ".*/wifisetup/.*")
endif()

set(NYMEA_REMOTEPROXYCLIENT_MODULE
    ${CMAKE_SOURCE_DIR}/nymea-remoteproxy/cmake/nymea-remoteproxyclient-sources.cmake
)

set(REMOTE_PROXYCLIENT_SOURCES)
set(REMOTE_PROXYCLIENT_HEADERS)
set(REMOTE_PROXYCLIENT_INCLUDE_DIRS)

if(EXISTS ${NYMEA_REMOTEPROXYCLIENT_MODULE})
    include(${NYMEA_REMOTEPROXYCLIENT_MODULE})

    if(COMMAND nymea_remoteproxyclient_sources)
        nymea_remoteproxyclient_sources(
            REMOTE_PROXYCLIENT_SOURCES
            REMOTE_PROXYCLIENT_HEADERS
            REMOTE_PROXYCLIENT_INCLUDE_DIRS
        )
    endif()

    if(DEFINED NYMEA_REMOTEPROXYCLIENT_SOURCES)
        list(APPEND REMOTE_PROXYCLIENT_SOURCES ${NYMEA_REMOTEPROXYCLIENT_SOURCES})
    endif()
    if(DEFINED NYMEA_REMOTEPROXYCLIENT_HEADERS)
        list(APPEND REMOTE_PROXYCLIENT_HEADERS ${NYMEA_REMOTEPROXYCLIENT_HEADERS})
    endif()
    if(DEFINED NYMEA_REMOTEPROXYCLIENT_INCLUDE_DIRS)
        list(APPEND REMOTE_PROXYCLIENT_INCLUDE_DIRS ${NYMEA_REMOTEPROXYCLIENT_INCLUDE_DIRS})
    endif()

    if(NOT REMOTE_PROXYCLIENT_SOURCES AND NOT REMOTE_PROXYCLIENT_HEADERS)
        message(FATAL_ERROR
            "nymea-remoteproxyclient module did not populate its source lists. "
            "Please ensure nymea-remoteproxy is checked out at the required revision."
        )
    endif()
else()
    message(FATAL_ERROR
        "nymea-remoteproxyclient CMake module not found. Did you initialize the nymea-remoteproxy submodule?"
    )
endif()

if(NOT REMOTE_PROXYCLIENT_INCLUDE_DIRS)
    set(_nymea_remoteproxyclient_root
        ${CMAKE_SOURCE_DIR}/nymea-remoteproxy/libnymea-remoteproxyclient
    )
    if(EXISTS ${_nymea_remoteproxyclient_root})
        list(APPEND REMOTE_PROXYCLIENT_INCLUDE_DIRS ${_nymea_remoteproxyclient_root})
    endif()
    unset(_nymea_remoteproxyclient_root)
endif()

if(NOT REMOTE_PROXYCLIENT_INCLUDE_DIRS)
    message(FATAL_ERROR
        "nymea-remoteproxyclient include directories were not provided by the module. "
        "Please ensure the nymea-remoteproxy submodule is checked out at the required revision."
    )
endif()

set(NYMEA_APP_CORE_INCLUDE_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_BINARY_DIR}
)

# Add all subdirectories as include paths (sources use flat includes like "actionhandler.h")
file(GLOB_RECURSE _all_headers CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
foreach(_header ${_all_headers})
    get_filename_component(_dir ${_header} DIRECTORY)
    list(APPEND NYMEA_APP_CORE_INCLUDE_DIRS ${_dir})
endforeach()
list(REMOVE_DUPLICATES NYMEA_APP_CORE_INCLUDE_DIRS)

list(APPEND NYMEA_APP_CORE_INCLUDE_DIRS ${REMOTE_PROXYCLIENT_INCLUDE_DIRS})

if(EXISTS ${CMAKE_SOURCE_DIR}/QtZeroConf)
    list(APPEND NYMEA_APP_CORE_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/QtZeroConf)
endif()

if(EMSCRIPTEN)
    list(FILTER REMOTE_PROXYCLIENT_SOURCES EXCLUDE REGEX "tcpsocketconnection\\.cpp$")
    list(FILTER REMOTE_PROXYCLIENT_HEADERS EXCLUDE REGEX "tcpsocketconnection\\.h$")
endif()

add_library(nymea-app-core STATIC
    ${LIBNYMEA_APP_SOURCES}
    ${LIBNYMEA_APP_HEADERS}
    ${REMOTE_PROXYCLIENT_SOURCES}
    ${REMOTE_PROXYCLIENT_HEADERS}
)
set_target_properties(nymea-app-core PROPERTIES OUTPUT_NAME "nymea-app")

list(REMOVE_DUPLICATES NYMEA_APP_CORE_INCLUDE_DIRS)
target_include_directories(nymea-app-core PUBLIC ${NYMEA_APP_CORE_INCLUDE_DIRS})

target_link_libraries(nymea-app-core
    PUBLIC
        Qt6::Core
        Qt6::Network
        Qt6::WebSockets
        Qt6::Charts
        Qt6::Quick
        Qt6::Qml
)

if(NOT EMSCRIPTEN)
    target_link_libraries(nymea-app-core PUBLIC Qt6::Bluetooth)
endif()

if(TARGET OpenSSL::SSL AND TARGET OpenSSL::Crypto)
    target_link_libraries(nymea-app-core PUBLIC OpenSSL::SSL OpenSSL::Crypto)
else()
    message(WARNING "OpenSSL development libraries not found; continuing without explicit OpenSSL linkage.")
endif()

if(IOS)
    target_link_libraries(nymea-app-core PUBLIC "-framework SystemConfiguration")
endif()

if(NYMEA_ENABLE_ZEROCONF)
    target_compile_definitions(nymea-app-core PUBLIC WITH_ZEROCONF QZEROCONF_STATIC)
    find_library(QTZEROCONF_LIBRARY NAMES QtZeroConf HINTS ${CMAKE_SOURCE_DIR}/QtZeroConf)
    if(NOT QTZEROCONF_LIBRARY AND TARGET Qt6::QtZeroConf)
        target_link_libraries(nymea-app-core PUBLIC Qt6::QtZeroConf)
    elseif(QTZEROCONF_LIBRARY)
        target_link_libraries(nymea-app-core PUBLIC ${QTZEROCONF_LIBRARY})
    else()
        message(FATAL_ERROR "ZeroConf support requested but QtZeroConf library was not found")
    endif()
endif()
