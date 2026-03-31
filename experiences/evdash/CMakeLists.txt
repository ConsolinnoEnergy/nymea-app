file(GLOB EVDASH_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp
)
file(GLOB EVDASH_HEADERS CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.h
)

add_library(nymea-app-evdash STATIC
    ${EVDASH_SOURCES}
    ${EVDASH_HEADERS}
)
set_target_properties(nymea-app-evdash PROPERTIES OUTPUT_NAME "nymea-app-evdash")

target_include_directories(nymea-app-evdash
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/libnymea-app
        ${CMAKE_BINARY_DIR}
)

target_link_libraries(nymea-app-evdash
    PUBLIC
        nymea-app-core
        Qt6::Core
        Qt6::Network
        Qt6::WebSockets
        Qt6::Bluetooth
        Qt6::Charts
        Qt6::Quick
        Qt6::Qml
)
