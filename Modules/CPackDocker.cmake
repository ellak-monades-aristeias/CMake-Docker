#.rst:
# CPackDocker
# --------
#
# The builtin (binary) CPack Docker generator (Unix only)
#
# Variables specific to CPack Docker generator
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# CPackDocker may be used to create Docker containers using CPack.
# CPackDocker is a CPack generator thus it uses the CPACK_XXX variables
# used by CPack : http://www.cmake.org/Wiki/CMake:CPackConfiguration.
#
# CPackDocker has specific features which are controlled by the specific
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
#
# .. variable:: CPACK_DOCKER_CONTAINER_VERSION
#
#  The Docker container version
#
#  * Mandatory : NO
#  * Default   : :variable:`CPACK_PACKAGE_VERSION`
#
#
# .. variable:: CPACK_DOCKER_CONTAINER_DESCRIPTION
#
#  The Docker container description
#
#  * Mandatory : NO
#  * Default   :
#
#    - :variable:`CPACK_DOCKER_CONTAINER_DESCRIPTION` if set or
#    - :variable:`CPACK_PACKAGE_DESCRIPTION_SUMMARY`
#
#
# .. variable:: CPACK_DOCKER_FROM
#
#  The Docker base image for subsequent instructions.
#
#  * Mandatory : YES
#  * Default   : 'ubuntu'
#
#  Example::
#
#    set(CPACK_DOCKER_FROM "ubuntu:14.04")
#
#
# .. variable:: CPACK_DOCKER_PACKAGE_MANAGER
#
#  Sets the Docker package manager for the base image.
#
#  * Mandatory : NO
#  * Default   : 
#
#    - :variable:`CPACK_DOCKER_PACKAGE_MANAGER` if set or
#    - Output of common package manager queries in the base image
#
#  Example::
#
#    set(CPACK_DOCKER_PACKAGE_MANAGER "yum")
#
#
# .. variable:: CPACK_DOCKER_PACKAGE_DEPENDS
#
#  List of package dependencies to be installed using the 
#  :code:`CPACK_DOCKER_PACKAGE_MANAGER` in the docker base image.
#
#  * Mandatory : NO
#  * Default   :
#
#  Example::
#
#    set(CPACK_DOCKER_PACKAGE_DEPENDS libc6 cmake=2.8.* build-utils)
# 
#
# .. variable:: CPACK_DOCKER_RUN_PREDEPENDS
#
#  Adds a custom Docker RUN directive to the Dockerfile before the
#  installation of the package dependencies.
#
#  * Mandatory : NO
#  * Default   :
#
#  Example::
#
#    set(CPACK_DOCKER_RUN_PREDEPENDS "add-apt-repository -y ppa:example/example")
# 
#
# .. variable:: CPACK_DOCKER_RUN_POSTDEPENDS
#
#  Adds a custom Docker RUN directive to the Dockerfile after the
#  installation of the package dependencies.
#
#  * Mandatory : NO
#  * Default   :
#
#  Example::
#
#    set(CPACK_DOCKER_RUN_POSTDEPENDS "pip install --upgrade pip")
#    set(CPACK_DOCKER_RUN_POSTDEPENDS "mkdir -p source;cd source")
# 
#
# .. variable:: CPACK_DOCKER_ADD
#
#  Adds a custom Docker ADD directive to the Dockerfile.
#
#  * Mandatory : NO
#  * Default   :
#
#  Example::
#
#    set(CPACK_DOCKER_ADD "example.tar.gz /example.tar.gz")
# 
#
# .. variable:: CPACK_DOCKER_COPY
#
#  Adds a custom Docker COPY directive to the Dockerfile.
#
#  * Mandatory : NO
#  * Default   :
#
#  Example::
#
#    set(CPACK_DOCKER_COPY "example.tar.gz /example.tar.gz")
# 
#
# .. variable:: CPACK_DOCKER_CMD
#
#  Adds the CMD command on the Dockerfile
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_CMD "/bin/bash --help")
# 
#
# .. variable:: CPACK_DOCKER_LABEL
#
#  Adds custom labels on the Dockerfile
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_LABEL author=me test)
# 
#
# .. variable:: CPACK_DOCKER_EXPOSE
#
#  Exposes tcp/udp ports on the host
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_EXPOSE 80 8080)
# 
#
# .. variable:: CPACK_DOCKER_ENV
#
#  Updates the environment variables of the Docker image
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_ENV "PATH /usr/local/bin:$PATH")
# 
#
# .. variable:: CPACK_DOCKER_ENTRYPOINT
#
#  Sets the image's main command
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_ENTRYPOINT "/entrypoint.sh")
# 
#
# .. variable:: CPACK_DOCKER_VOLUME
#
#  Creates a mount point for the image
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_VOLUME "/volume")
# 
#
# .. variable:: CPACK_DOCKER_USER
#
#  Sets the USER of the running Docker image
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_USER "root")
# 
#
# .. variable:: CPACK_DOCKER_WORKDIR
#
#  Sets the working directory for any commands that follow in the Dockerfile
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_WORKDIR "/root/")
# 
#
# .. variable:: CPACK_DOCKER_ONBUILD
#
#  Adds a trigger instruction to be executed when the image is used as a base
#  for another build
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_ONBUILD "RUN /bin/bash")
# 
#
# .. variable:: CPACK_DOCKER_CONTAINER_HOMEPAGE
#
#  Adds a label with the container homepage
#
#  * Mandatory : NO
#  * Default   : 
#
#  Example::
#
#    set(CPACK_DOCKER_CONTAINER_HOMEPAGE "http://www.example.com/")

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
  if(NOT CPACK_DOCKER_CONTAINER_NAME)
    set(CPACK_DOCKER_CONTAINER_NAME ${CPACK_PACKAGE_NAME})
  endif()

  # Maintainer: (recommended)
  if(NOT CPACK_DOCKER_MAINTAINER)
    if(NOT CPACK_PACKAGE_CONTACT)
      message(STATUS "CPackDocker: Docker package recommends a maintainer for a package, set CPACK_PACKAGE_CONTACT or CPACK_DOCKER_MAINTAINER")
    endif()
    set(CPACK_DOCKER_MAINTAINER ${CPACK_PACKAGE_CONTACT})
  endif()

# Version: (recommended)
  if(NOT CPACK_DOCKER_CONTAINER_VERSION)
    if(NOT CPACK_PACKAGE_VERSION)
      message(STATUS "CPackDocker: Docker recommends a container version")
    endif()
    set(CPACK_DOCKER_CONTAINER_VERSION ${CPACK_PACKAGE_VERSION})
  endif()

  # Description: (recommended)
  if(NOT CPACK_DOCKER_CONTAINER_DESCRIPTION)
    if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
      message(STATUS "CPackDocker: Docker package recommends a description for a container")
    endif()
    set(CPACK_DOCKER_CONTAINER_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
  endif()

  # Base image: (mandatory)
  if(NOT CPACK_DOCKER_FROM)
    set(CPACK_DOCKER_FROM "ubuntu")
    message(STATUS "CPackDocker: Docker package requires a base image, defaulting to ubuntu")
  endif()

  # Package manager: (recommended)
  if(NOT CPACK_DOCKER_PACKAGE_MANAGER)
    message(STATUS "CPackDocker: CPack will try to automatically assign the correct package manager")
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
  set(GEN_CPACK_DOCKER_CONTAINER_NAME         "${CPACK_DOCKER_CONTAINER_NAME}"        PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_MAINTAINER             "${CPACK_DOCKER_MAINTAINER}"            PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_CONTAINER_VERSION      "${CPACK_DOCKER_CONTAINER_VERSION}"     PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_CONTAINER_DESCRIPTION  "${CPACK_DOCKER_CONTAINER_DESCRIPTION}" PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_FROM                   "${CPACK_DOCKER_FROM}"                  PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_MANAGER        "${CPACK_DOCKER_PACKAGE_MANAGER}"       PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_PACKAGE_DEPENDS        "${CPACK_DOCKER_PACKAGE_DEPENDS}"       PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_RUN_PREDEPENDS         "${CPACK_DOCKER_RUN_PREDEPENDS}"        PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_RUN_POSTDEPENDS        "${CPACK_DOCKER_RUN_POSTDEPENDS}"       PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_ADD                    "${CPACK_DOCKER_ADD}"                   PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_COPY                   "${CPACK_DOCKER_COPY}"                  PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_CMD                    "${CPACK_DOCKER_CMD}"                   PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_LABEL                  "${CPACK_DOCKER_LABEL}"                 PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_EXPOSE                 "${CPACK_DOCKER_EXPOSE}"                PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_ENV                    "${CPACK_DOCKER_ENV}"                   PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_ENTRYPOINT             "${CPACK_DOCKER_ENTRYPOINT}"            PARENT_SCOPE)
  set(GEN_CPACK_DOKCER_VOLUME                 "${CPACK_DOCKER_VOLUME}"                PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_USER                   "${CPACK_DOCKER_USER}"                  PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_WORKDIR                "${CPACK_DOCKER_WORKDIR}"               PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_ONBUILD                "${CPACK_DOCKER_ONBUILD}"               PARENT_SCOPE)
  set(GEN_CPACK_DOCKER_CONTAINER_HOMEPAGE     "${CPACK_DOCKER_CONTAINER_HOMEPAGE}"     PARENT_SCOPE)
  set(GEN_WDIR                                "${WDIR}"                               PARENT_SCOPE)
endfunction()

cpack_docker_prepare_package_vars()
