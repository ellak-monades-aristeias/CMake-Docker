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
# .. variable:: CPACK_DOCKER_PACKAGE_VERSION
#
#  The Docker package version
#
#  * Mandatory : YES
#  * Default   : :variable:`CPACK_PACKAGE_VERSION`
#
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

  # per component automatic discover: some of the component might not have
  # binaries.
  if(CPACK_DEB_PACKAGE_COMPONENT)
    string(TOUPPER "${CPACK_DEB_PACKAGE_COMPONENT}" _local_component_name)
    set(_component_shlibdeps_var "CPACK_DEBIAN_${_local_component_name}_PACKAGE_SHLIBDEPS")

    # if set, overrides the global configuration
    if(DEFINED ${_component_shlibdeps_var})
      set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS "${${_component_shlibdeps_var}}")
      if(CPACK_DEBIAN_PACKAGE_DEBUG)
        message("CPackDeb Debug: component '${CPACK_DEB_PACKAGE_COMPONENT}' dpkg-shlibdeps set to ${CPACK_DEBIAN_PACKAGE_SHLIBDEPS}")
      endif()
    endif()
  endif()

  if(CPACK_DEBIAN_PACKAGE_SHLIBDEPS)
    # dpkg-shlibdeps is a Debian utility for generating dependency list
    find_program(SHLIBDEPS_EXECUTABLE dpkg-shlibdeps)

    if(SHLIBDEPS_EXECUTABLE)
      # Check version of the dpkg-shlibdeps tool using CPackRPM method
      execute_process(COMMAND env LC_ALL=C ${SHLIBDEPS_EXECUTABLE} --version
        OUTPUT_VARIABLE _TMP_VERSION
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      if(_TMP_VERSION MATCHES "dpkg-shlibdeps version ([0-9]+\\.[0-9]+\\.[0-9]+)")
        set(SHLIBDEPS_EXECUTABLE_VERSION "${CMAKE_MATCH_1}")
      else()
        set(SHLIBDEPS_EXECUTABLE_VERSION "")
      endif()

      if(CPACK_DEBIAN_PACKAGE_DEBUG)
        message("CPackDeb Debug: dpkg-shlibdeps --version output is '${_TMP_VERSION}'")
        message("CPackDeb Debug: dpkg-shlibdeps version is <${SHLIBDEPS_EXECUTABLE_VERSION}>")
      endif()

      # Generating binary list - Get type of all install files
      cmake_policy(PUSH)
        # Tell file(GLOB_RECURSE) not to follow directory symlinks
        # even if the project does not set this policy to NEW.
        cmake_policy(SET CMP0009 NEW)
        file(GLOB_RECURSE FILE_PATHS_ LIST_DIRECTORIES false RELATIVE "${WDIR}" "${WDIR}/*")
      cmake_policy(POP)

      # get file info so that we can determine if file is executable or not
      unset(CPACK_DEB_INSTALL_FILES)
      foreach(FILE_ IN LISTS FILE_PATHS_)
        execute_process(COMMAND file "./${FILE_}"
          WORKING_DIRECTORY "${WDIR}"
          OUTPUT_VARIABLE INSTALL_FILE_)
        list(APPEND CPACK_DEB_INSTALL_FILES "${INSTALL_FILE_}")
      endforeach()

      # Only dynamically linked ELF files are included
      # Extract only file name infront of ":"
      foreach(_FILE ${CPACK_DEB_INSTALL_FILES})
        if( ${_FILE} MATCHES "ELF.*dynamically linked")
           string(REGEX MATCH "(^.*):" _FILE_NAME "${_FILE}")
           list(APPEND CPACK_DEB_BINARY_FILES "${CMAKE_MATCH_1}")
           set(CONTAINS_EXECUTABLE_FILES_ TRUE)
        endif()
      endforeach()

      if(CONTAINS_EXECUTABLE_FILES_)
        message("CPackDeb: - Generating dependency list")

        # Create blank control file for running dpkg-shlibdeps
        # There might be some other way to invoke dpkg-shlibdeps without creating this file
        # but standard debian package should not have anything that can collide with this file or directory
        file(MAKE_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}/debian)
        file(WRITE ${CPACK_TEMPORARY_DIRECTORY}/debian/control "")

        # Add --ignore-missing-info if the tool supports it
        execute_process(COMMAND env LC_ALL=C ${SHLIBDEPS_EXECUTABLE} --help
          OUTPUT_VARIABLE _TMP_HELP
          ERROR_QUIET
          OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(_TMP_HELP MATCHES "--ignore-missing-info")
          set(IGNORE_MISSING_INFO_FLAG "--ignore-missing-info")
        endif()

        # Execute dpkg-shlibdeps
        # --ignore-missing-info : allow dpkg-shlibdeps to run even if some libs do not belong to a package
        # -O : print to STDOUT
        execute_process(COMMAND ${SHLIBDEPS_EXECUTABLE} ${IGNORE_MISSING_INFO_FLAG} -O ${CPACK_DEB_BINARY_FILES}
          WORKING_DIRECTORY "${CPACK_TEMPORARY_DIRECTORY}"
          OUTPUT_VARIABLE SHLIBDEPS_OUTPUT
          RESULT_VARIABLE SHLIBDEPS_RESULT
          ERROR_VARIABLE SHLIBDEPS_ERROR
          OUTPUT_STRIP_TRAILING_WHITESPACE )
        if(CPACK_DEBIAN_PACKAGE_DEBUG)
          # dpkg-shlibdeps will throw some warnings if some input files are not binary
          message( "CPackDeb Debug: dpkg-shlibdeps warnings \n${SHLIBDEPS_ERROR}")
        endif()
        if(NOT SHLIBDEPS_RESULT EQUAL 0)
          message (FATAL_ERROR "CPackDeb: dpkg-shlibdeps: '${SHLIBDEPS_ERROR}';\n"
              "executed command: '${SHLIBDEPS_EXECUTABLE} ${IGNORE_MISSING_INFO_FLAG} -O ${CPACK_DEB_BINARY_FILES}';\n"
              "found files: '${INSTALL_FILE_}';\n"
              "files info: '${CPACK_DEB_INSTALL_FILES}';\n"
              "binary files: '${CPACK_DEB_BINARY_FILES}'")
        endif()

        #Get rid of prefix generated by dpkg-shlibdeps
        string(REGEX REPLACE "^.*Depends=" "" CPACK_DEBIAN_PACKAGE_AUTO_DEPENDS "${SHLIBDEPS_OUTPUT}")

        if(CPACK_DEBIAN_PACKAGE_DEBUG)
          message("CPackDeb Debug: Found dependency: ${CPACK_DEBIAN_PACKAGE_AUTO_DEPENDS} from output ${SHLIBDEPS_OUTPUT}")
        endif()

        # Remove blank control file
        # Might not be safe if package actual contain file or directory named debian
        file(REMOVE_RECURSE "${CPACK_TEMPORARY_DIRECTORY}/debian")
      else()
        if(CPACK_DEBIAN_PACKAGE_DEBUG)
          message(AUTHOR_WARNING "CPackDeb Debug: Using only user-provided depends because package does not contain executable files that link to shared libraries.")
        endif()
      endif()
    else()
      message("CPackDeb: Using only user-provided dependencies because dpkg-shlibdeps is not found.")
    endif()

  else()
    if(CPACK_DEBIAN_PACKAGE_DEBUG)
      message("CPackDeb Debug: Using only user-provided dependencies")
    endif()
  endif()

  # Let's define the control file found in debian package:

  # Binary package:
  # http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-binarycontrolfiles

  # DEBIAN/control
  # debian policy enforce lower case for package name
  # Package: (mandatory)
  if(NOT CPACK_DEBIAN_PACKAGE_NAME)
    string(TOLOWER "${CPACK_PACKAGE_NAME}" CPACK_DEBIAN_PACKAGE_NAME)
  endif()

  # Version: (mandatory)
  if(NOT CPACK_DEBIAN_PACKAGE_VERSION)
    if(NOT CPACK_PACKAGE_VERSION)
      message(FATAL_ERROR "CPackDeb: Debian package requires a package version")
    endif()
    set(CPACK_DEBIAN_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION})
  endif()

  # Architecture: (mandatory)
  if(NOT CPACK_DEBIAN_PACKAGE_ARCHITECTURE)
    # There is no such thing as i686 architecture on debian, you should use i386 instead
    # $ dpkg --print-architecture
    find_program(DPKG_CMD dpkg)
    if(NOT DPKG_CMD)
      message(STATUS "CPackDeb: Can not find dpkg in your path, default to i386.")
      set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE i386)
    endif()
    execute_process(COMMAND "${DPKG_CMD}" --print-architecture
      OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
      OUTPUT_STRIP_TRAILING_WHITESPACE
      )
  endif()

  # have a look at get_property(result GLOBAL PROPERTY ENABLED_FEATURES),
  # this returns the successful find_package() calls, maybe this can help
  # Depends:
  # You should set: DEBIAN_PACKAGE_DEPENDS
  # TODO: automate 'objdump -p | grep NEEDED'

  # if per-component dependency, overrides the global CPACK_DEBIAN_PACKAGE_DEPENDS
  # automatic dependency discovery will be performed afterwards.
  if(CPACK_DEB_PACKAGE_COMPONENT)
    set(_component_depends_var "CPACK_DEBIAN_${_local_component_name}_PACKAGE_DEPENDS")

    # if set, overrides the global dependency
    if(DEFINED ${_component_depends_var})
      set(CPACK_DEBIAN_PACKAGE_DEPENDS "${${_component_depends_var}}")
      if(CPACK_DEBIAN_PACKAGE_DEBUG)
        message("CPackDeb Debug: component '${_local_component_name}' dependencies set to '${CPACK_DEBIAN_PACKAGE_DEPENDS}'")
      endif()
    endif()
  endif()

  # at this point, the CPACK_DEBIAN_PACKAGE_DEPENDS is properly set
  # to the minimal dependency of the package
  # Append automatically discovered dependencies .
  if(NOT "${CPACK_DEBIAN_PACKAGE_AUTO_DEPENDS}" STREQUAL "")
    if (CPACK_DEBIAN_PACKAGE_DEPENDS)
      set (CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_AUTO_DEPENDS}, ${CPACK_DEBIAN_PACKAGE_DEPENDS}")
    else ()
      set (CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_AUTO_DEPENDS}")
    endif ()
  endif()

  if(NOT CPACK_DEBIAN_PACKAGE_DEPENDS)
    message(STATUS "CPACK_DEBIAN_PACKAGE_DEPENDS not set, the package will have no dependencies.")
  endif()

  # Maintainer: (mandatory)
  if(NOT CPACK_DEBIAN_PACKAGE_MAINTAINER)
    if(NOT CPACK_PACKAGE_CONTACT)
      message(FATAL_ERROR "CPackDeb: Debian package requires a maintainer for a package, set CPACK_PACKAGE_CONTACT or CPACK_DEBIAN_PACKAGE_MAINTAINER")
    endif()
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER ${CPACK_PACKAGE_CONTACT})
  endif()

  # Description: (mandatory)
  if(NOT CPACK_DEB_PACKAGE_COMPONENT)
    if(NOT CPACK_DEBIAN_PACKAGE_DESCRIPTION)
      if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
        message(FATAL_ERROR "CPackDeb: Debian package requires a summary for a package, set CPACK_PACKAGE_DESCRIPTION_SUMMARY or CPACK_DEBIAN_PACKAGE_DESCRIPTION")
      endif()
      set(CPACK_DEBIAN_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
    endif()
  else()
    set(component_description_var CPACK_COMPONENT_${_local_component_name}_DESCRIPTION)

    # component description overrides package description
    if(${component_description_var})
      set(CPACK_DEBIAN_PACKAGE_DESCRIPTION ${${component_description_var}})
    elseif(NOT CPACK_DEBIAN_PACKAGE_DESCRIPTION)
      if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
        message(FATAL_ERROR "CPackDeb: Debian package requires a summary for a package, set CPACK_PACKAGE_DESCRIPTION_SUMMARY or CPACK_DEBIAN_PACKAGE_DESCRIPTION or ${component_description_var}")
      endif()
      set(CPACK_DEBIAN_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
    endif()
  endif()

  # Section: (recommended)
  if(NOT CPACK_DEBIAN_PACKAGE_SECTION)
    set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
  endif()

  # Priority: (recommended)
  if(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)
    set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
  endif()

  # Compression: (recommended)
  if(NOT CPACK_DEBIAN_COMPRESSION_TYPE)
    set(CPACK_DEBIAN_COMPRESSION_TYPE "gzip")
  endif()


  # Recommends:
  # You should set: CPACK_DEBIAN_PACKAGE_RECOMMENDS

  # Suggests:
  # You should set: CPACK_DEBIAN_PACKAGE_SUGGESTS

  # CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
  # This variable allow advanced user to add custom script to the control.tar.gz (inside the .deb archive)
  # Typical examples are:
  # - conffiles
  # - postinst
  # - postrm
  # - prerm
  # Usage:
  # set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
  #    "${CMAKE_CURRENT_SOURCE_DIR/prerm;${CMAKE_CURRENT_SOURCE_DIR}/postrm")

  # Are we packaging components ?
  if(CPACK_DEB_PACKAGE_COMPONENT)
    # override values with per component version if set
    foreach(VAR_NAME_ "PACKAGE_CONTROL_EXTRA")
      if(CPACK_DEBIAN_${_local_component_name}_${VAR_NAME_})
        set(CPACK_DEBIAN_${VAR_NAME_} "${CPACK_DEBIAN_${_local_component_name}_${VAR_NAME_}}")
      endif()
    endforeach()

    set(CPACK_DEB_PACKAGE_COMPONENT_PART_NAME "-${CPACK_DEB_PACKAGE_COMPONENT}")
    string(TOLOWER "${CPACK_PACKAGE_NAME}${CPACK_DEB_PACKAGE_COMPONENT_PART_NAME}" CPACK_DEBIAN_PACKAGE_NAME)
  else()
    set(CPACK_DEB_PACKAGE_COMPONENT_PART_NAME "")
  endif()

  # Print out some debug information if we were asked for that
  if(CPACK_DEBIAN_PACKAGE_DEBUG)
     message("CPackDeb:Debug: CPACK_TOPLEVEL_DIRECTORY          = ${CPACK_TOPLEVEL_DIRECTORY}")
     message("CPackDeb:Debug: CPACK_TOPLEVEL_TAG                = ${CPACK_TOPLEVEL_TAG}")
     message("CPackDeb:Debug: CPACK_TEMPORARY_DIRECTORY         = ${CPACK_TEMPORARY_DIRECTORY}")
     message("CPackDeb:Debug: CPACK_OUTPUT_FILE_NAME            = ${CPACK_OUTPUT_FILE_NAME}")
     message("CPackDeb:Debug: CPACK_OUTPUT_FILE_PATH            = ${CPACK_OUTPUT_FILE_PATH}")
     message("CPackDeb:Debug: CPACK_PACKAGE_FILE_NAME           = ${CPACK_PACKAGE_FILE_NAME}")
     message("CPackDeb:Debug: CPACK_PACKAGE_INSTALL_DIRECTORY   = ${CPACK_PACKAGE_INSTALL_DIRECTORY}")
     message("CPackDeb:Debug: CPACK_TEMPORARY_PACKAGE_FILE_NAME = ${CPACK_TEMPORARY_PACKAGE_FILE_NAME}")
  endif()

  # For debian source packages:
  # debian/control
  # http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-sourcecontrolfiles

  # .dsc
  # http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-debiansourcecontrolfiles

  # Builds-Depends:
  #if(NOT CPACK_DEBIAN_PACKAGE_BUILDS_DEPENDS)
  #  set(CPACK_DEBIAN_PACKAGE_BUILDS_DEPENDS
  #    "debhelper (>> 5.0.0), libncurses5-dev, tcl8.4"
  #  )
  #endif()

  # move variables to parent scope so that they may be used to create debian package
  set(GEN_CPACK_DEBIAN_PACKAGE_NAME "${CPACK_DEBIAN_PACKAGE_NAME}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_VERSION "${CPACK_DEBIAN_PACKAGE_VERSION}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_SECTION "${CPACK_DEBIAN_PACKAGE_SECTION}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_PRIORITY "${CPACK_DEBIAN_PACKAGE_PRIORITY}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_ARCHITECTURE "${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_DEBIAN_PACKAGE_MAINTAINER}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_DESCRIPTION "${CPACK_DEBIAN_PACKAGE_DESCRIPTION}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_DEPENDS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_FAKEROOT_EXECUTABLE "${CPACK_DEBIAN_FAKEROOT_EXECUTABLE}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_COMPRESSION_TYPE "${CPACK_DEBIAN_COMPRESSION_TYPE}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_RECOMMENDS "${CPACK_DEBIAN_PACKAGE_RECOMMENDS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_SUGGESTS "${CPACK_DEBIAN_PACKAGE_SUGGESTS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_HOMEPAGE "${CPACK_DEBIAN_PACKAGE_HOMEPAGE}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_PREDEPENDS "${CPACK_DEBIAN_PACKAGE_PREDEPENDS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_ENHANCES "${CPACK_DEBIAN_PACKAGE_ENHANCES}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_BREAKS "${CPACK_DEBIAN_PACKAGE_BREAKS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_CONFLICTS "${CPACK_DEBIAN_PACKAGE_CONFLICTS}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_PROVIDES "${CPACK_DEBIAN_PACKAGE_PROVIDES}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_REPLACES "${CPACK_DEBIAN_PACKAGE_REPLACES}" PARENT_SCOPE)
  set(GEN_CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA}" PARENT_SCOPE)
  set(GEN_WDIR "${WDIR}" PARENT_SCOPE)
endfunction()

cpack_deb_prepare_package_vars()
