cmake_minimum_required(VERSION 3.24)
project(EnderalSTRPatch VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory(extern/CommonLibSSE-NG)
include(extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

add_commonlibsse_plugin(${PROJECT_NAME}
    AUTHOR "Nutman"
    NAME "EnderalSTRPatch"
    VERSION ${PROJECT_VERSION}
    USE_ADDRESS_LIBRARY
    SOURCES src/main.cpp)

# CommonLibSSE-NG headers assume SKSE/Impl/PCH.h is included first (std headers, stl::, "sv" literals).
# The library only applies it to itself (PRIVATE), so the plugin must do the same.
target_precompile_headers(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG/include/SKSE/Impl/PCH.h")
