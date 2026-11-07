cmake_minimum_required(VERSION 3.24)
project(EnderalSTRPatch VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

set(BUILD_TESTS OFF CACHE BOOL "" FORCE)

# Newer MSVC STL no longer includes these transitively; CommonLibSSE-NG headers assume they are there.
if(MSVC)
    foreach(h cstdint cstddef array stdexcept compare string string_view vector memory functional utility algorithm optional variant limits)
        add_compile_options(/FI${h})
    endforeach()
endif()
add_subdirectory(extern/CommonLibSSE-NG)
include(extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

add_commonlibsse_plugin(${PROJECT_NAME}
    AUTHOR "Nutman"
    NAME "EnderalSTRPatch"
    VERSION ${PROJECT_VERSION}
    USE_ADDRESS_LIBRARY
    SOURCES src/main.cpp)
