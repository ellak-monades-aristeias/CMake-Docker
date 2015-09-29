# CPack Example: User-selectable Installation Components
#
# In this example, we have a simple library (mylib) with an example
# application (mylibapp). We create a binary installer (a CPack Generator)
# which supports CPack components.

cmake_minimum_required(VERSION 2.8.3.20101130 FATAL_ERROR)
project(CMakeDockerTest)

# Use GNUInstallDirs in order to enforce lib64 if needed
include(GNUInstallDirs)

# Create the mylib library
add_library(mylib mylib.cpp)

# Create the mylibapp application
add_executable(mylibapp mylibapp.cpp)
target_link_libraries(mylibapp mylib)

# Duplicate of mylibapp application
# which won't be put in any component (?mistake?)
add_executable(mylibapp2 mylibapp.cpp)
target_link_libraries(mylibapp2 mylib)

# Create installation targets. Note that we put each kind of file
# into a different component via COMPONENT. These components will
# be used to create the installation components.
install(TARGETS mylib
  ARCHIVE
  DESTINATION ${CMAKE_INSTALL_LIBDIR}
  COMPONENT libraries)

install(TARGETS mylibapp
  RUNTIME
  DESTINATION bin
  COMPONENT applications)

install(FILES mylib.h
        DESTINATION include
        COMPONENT headers)

include(CMakeDocker)
create_development_dockerfile(
  TARGETS "ubuntu" "centos" "fedora" "base/archlinux"
)