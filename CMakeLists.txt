cmake_minimum_required(VERSION 3.11)
project(jini VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Wall -O2 -s")

include_directories(BEFORE SYSTEM ${JNI_INCLUDE_PATH} ${JNI_INCLUDE_PATH}/win32)

if (CMAKE_BUILD_TYPE STREQUAL "Release")
    add_library(jini STATIC src/libjini/jini.cpp)
else()
    add_library(jini SHARED src/libjini/jini.cpp)
endif()
