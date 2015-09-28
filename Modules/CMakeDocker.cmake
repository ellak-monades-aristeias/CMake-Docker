#.rst:
# CMakeDocker
# -----------
#
# The builtin (binary) CMake Docker generator (Unix only)
#
# Variables specific to CMake Docker generator
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# CMakeDocker may be used to create Docker containers using CPackDocker.
# CMakeDocker uses the CPackDocker generator to build development images
# and deployable packages for linux distributions by building the package
#
# You'll find a detailed usage on the wiki:
# http://www.cmake.org/Wiki/CMake:CPackPackageGenerators#Docker_.28UNIX_only.29 .
# However as a handy reminder here comes the list of specific variables:
#
# .. variable:: CPACK_DOCKER_CONTAINER_NAME
#
#  The Docker container name
#
#  * Mandatory : YES
#  * Default   : :variable:`CPACK_PACKAGE_NAME`
#
#
# .. variable:: CPACK_DOCKER_MAINTAINER
#
#  The Docker container maintainer
#
#  * Mandatory : NO
#  * Default   : :code:`CPACK_PACKAGE_CONTACT`
#

#=============================================================================
# Copyright 2007-2009 Kitware, Inc.
# Copyright 2007-2015 Aris Synodinos <arissynod@gmail.com>
# Copyright 2007-2015 Konstantinos Chatzilygeroudis <costashatz@gmail.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# CMake script for creating Docker containers
# Author: Aris Synodinos
#
# http://docs.docker.com/

if(CMAKE_BINARY_DIR)
  message(FATAL_ERROR "CMakeDocker.cmake may only be used by CMake/CPack internally.")
endif()

if(NOT UNIX)
  message(FATAL_ERROR "CMakeDocker.cmake may only be used under UNIX.")
endif()

function(create_dockerfile)

endfunction()

function(create_docker_container)

endfunction()