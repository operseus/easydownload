cmake_minimum_required(VERSION 3.20)
project(EasyDownloadCore CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(core
    main.cpp
)

set_target_properties(core PROPERTIES OUTPUT_NAME "core")

if(MSVC)
    target_compile_options(core PRIVATE /utf-8 /W3 /EHsc /permissive- /std:c++17)
    # Use the static runtime so core.exe ships without extra VC++ DLLs.
    set_property(TARGET core PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
else()
    target_compile_options(core PRIVATE -std=c++17)
endif()

target_include_directories(core PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(core PRIVATE Shell32)
