# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "h3_flutter_plus")
project(${PROJECT_NAME} LANGUAGES CXX)

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/include/h3lib" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set(h3_flutter_plus_bundled_libraries
  # Defined in ../include/h3lib/CMakeLists.txt.
  $<TARGET_FILE:h3>
  PARENT_SCOPE
)
