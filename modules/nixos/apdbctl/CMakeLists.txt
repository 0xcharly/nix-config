cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED VERSION)
    execute_process(COMMAND git describe --tags --abbrev=0
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if("${VERSION}" STREQUAL "")
        message(FATAL_ERROR "VERSION is not set and failed to get from git")
    endif()
endif()

string(REGEX REPLACE "^v" "" VERSION "${VERSION}")

project(apdbctl VERSION ${VERSION} LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(DISTRIBUTOR "Unset" CACHE STRING "Distributor")

# Find hidapi library
find_package(PkgConfig REQUIRED)
pkg_check_modules(HIDAPI REQUIRED hidapi-hidraw)

# Add executable
add_executable(apdbctl
    src/main.c
)
target_compile_definitions(apdbctl PRIVATE
    PROJECT_NAME="${PROJECT_NAME}"
    VERSION="${VERSION}"
)

# Link against hidapi
target_link_libraries(apdbctl ${HIDAPI_LIBRARIES})
target_include_directories(apdbctl PRIVATE ${HIDAPI_INCLUDE_DIRS})
target_compile_options(apdbctl PRIVATE ${HIDAPI_CFLAGS_OTHER})

# Installation
install(TARGETS apdbctl DESTINATION bin)
