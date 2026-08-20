file(GLOB RFID_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp
)
file(GLOB RFID_HEADERS CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.h
)

add_library(nymea-app-rfid STATIC
    ${RFID_SOURCES}
    ${RFID_HEADERS}
)
set_target_properties(nymea-app-rfid PROPERTIES OUTPUT_NAME "nymea-app-rfid")

target_include_directories(nymea-app-rfid
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/libnymea-app
        ${CMAKE_BINARY_DIR}
)

target_link_libraries(nymea-app-rfid
    PUBLIC
        nymea-app-core
        Qt6::Core
        Qt6::Network
        Qt6::WebSockets
        Qt6::Quick
        Qt6::Qml
)
