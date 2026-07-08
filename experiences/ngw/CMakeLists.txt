file(GLOB NGW_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp
)
file(GLOB NGW_HEADERS CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/*.h
)

add_library(nymea-app-ngw STATIC
    ${NGW_SOURCES}
    ${NGW_HEADERS}
)
set_target_properties(nymea-app-ngw PROPERTIES OUTPUT_NAME "nymea-app-ngw")

target_include_directories(nymea-app-ngw
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/libnymea-app
        ${CMAKE_BINARY_DIR}
)

target_link_libraries(nymea-app-ngw
    PUBLIC
        nymea-app-core
        Qt6::Core
        Qt6::Network
        Qt6::WebSockets
        Qt6::Quick
        Qt6::Qml
)
