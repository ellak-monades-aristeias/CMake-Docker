#.rst:
# CMakeDocker
# -----------
#
# The builtin (binary) CMake Docker generator (Unix only)
# Requires CMake 2.6 or greater because it uses function and
# PARENT_SCOPE.  Also depends on CPackDocker.cmake.
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

# Include CPack to introduce the appropriate targets
include(CPack)

if(CMAKE_BINARY_DIR)
  message(FATAL_ERROR "CMakeDocker.cmake may only be used by CMake/CPack internally.")
endif()

if(NOT UNIX)
  message(FATAL_ERROR "CMakeDocker.cmake may only be used under UNIX.")
endif()

function(CREATE_CONTAINER)
  set(options UPLOAD DELETE)
  set(oneValueArgs USERNAME)
  set(multiValueArgs TARGETS TAGS)
  cmake_parse_arguments(CREATE_CONTAINER "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

  if(NOT CREATE_CONTAINER_TARGETS)
    message(FATAL_ERROR "CREATE_CONTAINER called without TARGETS specified")
  endif()

  if(NOT CREATE_CONTAINER_TAGS)
    message(FATAL_ERROR "CREATE_CONTAINER called without TAGS specified")
  endif()

  list(LENGTH CREATE_CONTAINER_TARGETS TARGETS_LENGTH)
  list(LENGTH CREATE_CONTAINER_TAGS TAGS_LENGTH)

  if(NOT TARGETS_LENGTH EQUAL TAGS_LENGTH)
    message(FATAL_ERROR "TARGETS and TAGS must be of the same size")
  endif()

  # Append / at the username
  if(${CREATE_CONTAINER_USERNAME})
    set(${CREATE_CONTAINER_USERNAME} "${CREATE_CONTAINER_USERNAME}/")
  endif()

  find_program(DOCKER_EXECUTABLE docker)
  if(DOCKER_EXECUTABLE)
    foreach(INDEX RANGE ${TARGETS_LENGTH})
      list(GET CREATE_CONTAINER_TARGETS ${index} _target)
      list(GET CREATE_CONTAINER_TAGS ${index} _tag)
      # Build the container
      execute_process(
        COMMAND ${DOCKER_EXECUTABLE} build --file=${_target} --tag=${CREATE_CONTAINER_USERNAME}${_tag}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        OUTPUT_VARIABLE BUILD_OUTPUT
        RESULT_VARIABLE BUILD_RESULT
        ERROR_VARIABLE  BUILD_ERROR
      )
      if(CREATE_CONTAINER_UPLOAD)
        if(NOT CREATE_CONTAINER_USERNAME)
          message(FATAL_ERROR "Cannot upload container to dockerhub without a USERNAME specified")
        endif()
        execute_process(
          COMMAND ${DOCKER_EXECUTABLE} push ${CREATE_CONTAINER_USERNAME}${_tag}
          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
          OUTPUT_VARIABLE UPLOAD_OUTPUT
          RESULT_VARIABLE UPLOAD_RESULT
          ERROR_VARIABLE  UPLOAD_ERROR
        )
      endif()
      if(CREATE_CONTAINER_DELETE)
        execute_process(
          COMMAND ${DOCKER_EXECUTABLE} rmi -f ${CREATE_CONTAINER_USERNAME}${_tag}
          WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
          OUTPUT_VARIABLE DELETE_OUTPUT
          RESULT_VARIABLE DELETE_RESULT
          ERROR_VARIABLE  DELETE_ERROR          
        )
      endif()
    endforeach()
  else()
    message(FATAL_ERROR "CREATE_CONTAINER called without docker executable being present")
  endif()
  set(${CREATE_CONTAINER_OUTPUT} "${BUILD_OUTPUT};${UPLOAD_OUTPUT};${DELETE_OUTPUT}" PARENT_SCOPE)
  set(${CREATE_CONTAINER_RESULT} "${BUILD_RESULT};${UPLOAD_RESULT};${DELETE_RESULT}" PARENT_SCOPE)
  set(${CREATE_CONTAINER_ERROR}  "${BUILD_ERROR};${UPLOAD_ERROR};${DELETE_ERROR}"    PARENT_SCOPE)
endfunction()

