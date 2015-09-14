#.rst:
# CPackDocker
# --------
#
# The builtin (binary) CPack Docker generator (Unix only)
#
# Variables specific to CPack Docker generator
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# CPackDocker may be used to create Docker package using CPack.
# CPackDocker is a CPack generator thus it uses the CPACK_XXX variables
# used by CPack : http://www.cmake.org/Wiki/CMake:CPackConfiguration.
#
# CPackDocker has specific features which are controlled by the specifics
# :code:`CPACK_DOCKER_XXX` variables.
#
# :code:`CPACK_DOCKER_<COMPONENT>_XXXX` variables may be used in order to have
# **component** specific values.  Note however that <COMPONENT> refers to the
# **grouping name** written in upper case. It may be either a component name or
# a component GROUP name.
#
# You'll find a detailed usage on the wiki:
# http://www.cmake.org/Wiki/CMake:CPackPackageGenerators#Docker_.28UNIX_only.29 .
# However as a handy reminder here comes the list of specific variables:
#
# .. variable:: CPACK_DOCKER_PACKAGE_NAME
#
#  The Docker package summary
#
#  * Mandatory : YES
#  * Default   : :variable:`CPACK_PACKAGE_NAME` (lower case)
#
#
# .. variable:: CPACK_DOCKER_BASE_IMAGE
#
#  The Docker base image (FROM)
#
#  * Mandatory : YES
#  * Default   : 'ubuntu'
#
#
# .. variable:: CPACK_DOCKER_PACKAGE_VERSION
#
#  The Docker package version
#
#  * Mandatory : YES
#  * Default   : :variable:`CPACK_PACKAGE_VERSION`
#
#
# .. variable:: CPACK_DOCKER_PACKAGE_MANAGER
#
#  Sets the Docker package manager of this package.
#
#  * Mandatory : NO
#  * Default   : 'apt-get'
#
#  Example::
#
#    set(CPACK_DOCKER_PACKAGE_MANAGER "yum")
#
# .. variable:: CPACK_DOCKER_PACKAGE_DEPENDS
#               CPACK_DOCKER_<COMPONENT>_PACKAGE_DEPENDS
#
#  Sets the Docker dependencies of this package.
#
#  * Mandatory : NO
#  * Default   :
#
#    - An empty string for non-component based installations
#    - :variable:`CPACK_DOCKER_PACKAGE_DEPENDS` for component-based
#      installations.
#
#  Example::
#
#    set(CPACK_DOCKER_PACKAGE_DEPENDS "libc6")
#
# .. variable:: CPACK_DOCKER_PACKAGE_MAINTAINER
#
#  The Docker package maintainer
#
#  * Mandatory : YES
#  * Default   : :code:`CPACK_PACKAGE_CONTACT`
#
#
# .. variable:: CPACK_DOCKER_PACKAGE_DESCRIPTION
#               CPACK_COMPONENT_<COMPONENT>_DESCRIPTION
#
#  The Docker package description
#
#  * Mandatory : NO
#  * Default   :
#
#    - :variable:`CPACK_DOCKER_PACKAGE_DESCRIPTION` if set or
#    - :variable:`CPACK_PACKAGE_DESCRIPTION_SUMMARY`
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

# CPack script for creating Debian package
# Author: Aris Synodinos
#
# http://docs.docker.com/

if(CMAKE_BINARY_DIR)
  message(FATAL_ERROR "CPackDocker.cmake may only be used by CPack internally.")
endif()

if(NOT UNIX)
  message(FATAL_ERROR "CPackDocker.cmake may only be used under UNIX.")
endif()

function(cpack_docker_prepare_package_vars)
  set(WDIR "${CPACK_TOPLEVEL_DIRECTORY}/${CPACK_PACKAGE_FILE_NAME}${CPACK_DOCKER_PACKAGE_COMPONENT_PART_PATH}")

  # Package: (mandatory)
  if(NOT CPACK_DOCKER_PACKAGE_NAME)
    set(CPACK_DOCKER_PACKAGE_NAME ${CPACK_PACKAGE_NAME})
  endif()

  # Base image: (mandatory)
  if(NOT CPACK_DOCKER_BASE_IMAGE)
    set(CPACK_DOCKER_BASE_IMAGE "ubuntu")
    message(STATUS "CPackDocker: Docker package requires a base image, defaulting to ubuntu")
  endif()

  # Package manager: (recommended)
  if(NOT CPACK_DOCKER_PACKAGE_MANAGER)
    set(CPACK_DOCKER_PACKAGE_MANAGER "apt-get")
    message(STATUS "CPackDocker: Docker package requires the definition of a package manager, defaulting to apt-get")
  endif()

  # Version: (recommended)
  if(NOT CPACK_DOCKER_PACKAGE_VERSION)
    if(NOT CPACK_PACKAGE_VERSION)
      message(STATUS "CPackDocker: Docker does not require a package version")
    endif()
    set(CPACK_DOCKER_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION})
  endif()

  # Maintainer: (mandatory)
  if(NOT CPACK_DOCKER_PACKAGE_MAINTAINER)
    if(NOT CPACK_PACKAGE_CONTACT)
      message(FATAL_ERROR "CPackDocker: Docker package requires a maintainer for a package, set CPACK_PACKAGE_CONTACT or CPACK_DOCKER_PACKAGE_MAINTAINER")
    endif()
    set(CPACK_DOCKER_PACKAGE_MAINTAINER ${CPACK_PACKAGE_CONTACT})
  endif()

  # Description: (recommended)
  if(NOT CPACK_DOCKER_PACKAGE_DESCRIPTION)
    if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
      message(FATAL_ERROR "CPackDocker: Docker package does not require a summary for a package")
    endif()
    set(CPACK_DOCKER_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
  endif()


  # Print out some debug information if we were asked for that
  if(CPACK_DOCKER_PACKAGE_DEBUG)
     message("CPackDocker:Debug: CPACK_TOPLEVEL_DIRECTORY          = ${CPACK_TOPLEVEL_DIRECTORY}")
     message("CPackDocker:Debug: CPACK_TOPLEVEL_TAG                = ${CPACK_TOPLEVEL_TAG}")
     message("CPackDocker:Debug: CPACK_TEMPORARY_DIRECTORY         = ${CPACK_TEMPORARY_DIRECTORY}")
     message("CPackDocker:Debug: CPACK_OUTPUT_FILE_NAME            = ${CPACK_OUTPUT_FILE_NAME}")
     message("CPackDocker:Debug: CPACK_OUTPUT_FILE_PATH            = ${CPACK_OUTPUT_FILE_PATH}")
     message("CPackDocker:Debug: CPACK_PACKAGE_FILE_NAME           = ${CPACK_PACKAGE_FILE_NAME}")
     message("CPackDocker:Debug: CPACK_PACKAGE_INSTALL_DIRECTORY   = ${CPACK_PACKAGE_INSTALL_DIRECTORY}")
     message("CPackDocker:Debug: CPACK_TEMPORARY_PACKAGE_FILE_NAME = ${CPACK_TEMPORARY_PACKAGE_FILE_NAME}")
  endif()

  # move variables to parent scope so that they may be used to create debian package
  set(GEN_CPACK_DOCKER_PACKAGE_NAME "${CPACK_DOCKER_PACKAGE_NAME}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_BASE_IMAGE "${CPACK_DOCKER_BASE_IMAGE}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_MANAGER "{CPACK_DOCKER_PACKAGE_MANAGER}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_VERSION "${CPACK_DOCKER_PACKAGE_VERSION}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_MAINTAINER "${CPACK_DOCKER_PACKAGE_MAINTAINER}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_DESCRIPTION "${CPACK_DOCKER_PACKAGE_DESCRIPTION}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_HOMEPAGE "${CPACK_DOCKER_PACKAGE_HOMEPAGE}" PARENT_SCOPE)
  set(GEN_WDIR "${WDIR}" PARENT_SCOPE)
endfunction()

cpack_docker_prepare_package_vars()
