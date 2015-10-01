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
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are not permitted. Make a separate folder for building:\nmkdir build; cd build; cmake ..\nBefore that, remove the files already created:\nrm -rf CMakeCache.txt CMakeFiles")
endif()

include(CMakeParseArguments)

if(NOT UNIX)
  message(FATAL_ERROR "CMakeDocker.cmake may only be used under UNIX.")
endif()

# Set the cpack generator
set(CPACK_GENERATOR DOCKER)
string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_BINARY_DIR ${CMAKE_BINARY_DIR})
install(DIRECTORY "${CMAKE_SOURCE_DIR}"
        DESTINATION "/"
        COMPONENT package_files
        PATTERN "${RELATIVE_BINARY_DIR}*" EXCLUDE)

set(CPACK_COMPONENTS_ALL package_files)
set(CPACK_DOCKER_COMPONENT_INSTALL "ON")

function(CREATE_DOCKERFILE)
  set(options "")
  set(oneValueArgs TARGET)
  set(multiValueArgs "")
  cmake_parse_arguments(CREATE_DOCKERFILE "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")
  if(NOT CREATE_DOCKERFILE_TARGET)
    message(FATAL_ERROR "CREATE_DOCKERFILE called without TARGET specified")
  endif()
  
  set(CPACK_DOCKER_BUILD_CONTAINER FALSE)
  get_filename_component(CPACK_DOCKER_CONTAINER_NAME ${CREATE_DOCKERFILE_TARGET} NAME_WE)
  set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_DOCKER_CONTAINER_NAME}")
  set(CPACK_DOCKER_CONTAINER_COMPONENT_PACKAGE_FILES_NAME "${CMAKE_PROJECT_NAME}-${CPACK_DOCKER_CONTAINER_NAME}")
  set(CPACK_PACKAGING_INSTALL_PREFIX "/")
  set(CPACK_DOCKER_FROM ${CREATE_DOCKERFILE_TARGET})
  set(CPACK_DOCKER_VOLUME "/home/${CPACK_DOCKER_CONTAINER_NAME}")
  set(CPACK_DOCKER_WORKDIR "/home/${CPACK_DOCKER_CONTAINER_NAME}")
  include(CPack)
endfunction()

function(CREATE_CONTAINER)
  set(options UPLOAD DELETE)
  set(oneValueArgs USERNAME TARGET TAG)
  set(multiValueArgs "")
  cmake_parse_arguments(CREATE_CONTAINER "${options}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

  if(NOT CREATE_CONTAINER_TARGET)
    message(FATAL_ERROR "CREATE_CONTAINER called without TARGET specified")
  endif()

  if(NOT CREATE_CONTAINER_TAG)
    message(WARN "CREATE_CONTAINER called without TAG specified")
    string(TOLOWER CREATE_CONTAINER_TAG ${CMAKE_PROJECT_NAME})
  endif()

  # Append / at the username
  if(${CREATE_CONTAINER_USERNAME})
    set(${CREATE_CONTAINER_USERNAME} "${CREATE_CONTAINER_USERNAME}/")
  endif()

  create_dockerfile(TARGET ${CREATE_CONTAINER_TARGET})

  set(DOCKERFILENAME "${CMAKE_PROJECT_NAME}-${CREATE_CONTAINER_TARGET}-package_files")

  find_program(DOCKER_EXECUTABLE docker)
  if(DOCKER_EXECUTABLE)
    execute_process(
      COMMAND ${DOCKER_EXECUTABLE} build --file=${DOCKERFILENAME} --tag=${CREATE_CONTAINER_USERNAME}${CREATE_CONTAINER_TAG}
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
        COMMAND ${DOCKER_EXECUTABLE} push ${CREATE_CONTAINER_USERNAME}${CREATE_CONTAINER_TAG}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        OUTPUT_VARIABLE UPLOAD_OUTPUT
        RESULT_VARIABLE UPLOAD_RESULT
        ERROR_VARIABLE  UPLOAD_ERROR
      )
    endif()
    if(CREATE_CONTAINER_DELETE)
      execute_process(
        COMMAND ${DOCKER_EXECUTABLE} rmi -f ${CREATE_CONTAINER_USERNAME}${CREATE_CONTAINER_TAG}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        OUTPUT_VARIABLE DELETE_OUTPUT
        RESULT_VARIABLE DELETE_RESULT
        ERROR_VARIABLE  DELETE_ERROR          
      )
    endif()
  else()
    message(FATAL_ERROR "CREATE_CONTAINER called without docker executable being present")
  endif()
  set(${CREATE_CONTAINER_OUTPUT} "${BUILD_OUTPUT};${UPLOAD_OUTPUT};${DELETE_OUTPUT}" PARENT_SCOPE)
  set(${CREATE_CONTAINER_RESULT} "${BUILD_RESULT};${UPLOAD_RESULT};${DELETE_RESULT}" PARENT_SCOPE)
  set(${CREATE_CONTAINER_ERROR}  "${BUILD_ERROR};${UPLOAD_ERROR};${DELETE_ERROR}"    PARENT_SCOPE)
endfunction()