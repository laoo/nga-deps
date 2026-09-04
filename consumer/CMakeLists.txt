# A throwaway consumer, built inside the workflow against the freshly installed
# prefix and nothing else.
#
# It answers the one question the whole single-archive design rests on: does the
# installed ortoolsConfig.cmake resolve its find_dependency() calls from within
# the prefix, with no abseil, protobuf or re2 anywhere on the machine? A build
# failure here is that question answered "no", and it costs a minute instead of
# being discovered from NGA's CI on three platforms.
#
# C++23, because that is what NGA is, and OR-Tools v9.15 builds itself as C++17
# (C++20 on MSVC).

cmake_minimum_required( VERSION 3.24 )
project( ortools_consumer CXX )

set( CMAKE_CXX_STANDARD 23 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )
set( CMAKE_CXX_EXTENSIONS OFF )

find_package( ortools CONFIG REQUIRED )

add_executable( consumer Consumer.cpp )
target_link_libraries( consumer PRIVATE ortools::ortools )
