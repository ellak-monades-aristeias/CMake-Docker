# KWSys Common Dashboard Script
#
# This script contains basic dashboard driver code common to all
# clients.
#
# Put this script in a directory such as "~/Dashboards/Scripts" or
# "c:/Dashboards/Scripts".  Create a file next to this script, say
# 'my_dashboard.cmake', with code of the following form:
#
#   # Client maintainer: me@mydomain.net
#   set(CTEST_SITE "machine.site")
#   set(CTEST_BUILD_NAME "Platform-Compiler")
#   set(CTEST_BUILD_CONFIGURATION Debug)
#   set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
#   include(${CTEST_SCRIPT_DIRECTORY}/kwsys_common.cmake)
#
# Then run a scheduled task (cron job) with a command line such as
#
#   ctest -S ~/Dashboards/Scripts/my_dashboard.cmake -V
#
# By default the source and build trees will be placed in the path
# "../My Tests/" relative to your script location.
#
# The following variables may be set before including this script
# to configure it:
#
#   dashboard_model       = Nightly | Experimental
#   dashboard_root_name   = Change name of "My Tests" directory
#   dashboard_do_coverage = True to enable coverage (ex: gcov)
#   dashboard_do_memcheck = True to enable memcheck (ex: valgrind)
#   dashboard_git_crlf    = Value of core.autocrlf for repository
#
#   KWSys_source_name     = Name of source directory (KWSys)
#   KWSys_binary_name     = Name of binary directory (KWSys-build)
#   KWSys_cache           = Initial CMakeCache.txt file content
#   KWSys_git_repo        = Custom Git clone url
#   KWSys_git_branch      = Custom remote branch to track
#   KWSys_topics_repo     = Custom topics repo url.
#   KWSys_topics_url      = Custom topics file url.
#
#   CTEST_GIT_COMMAND     = path to git command-line client
#   CTEST_BUILD_FLAGS     = build tool arguments (ex: -j2)
#   CTEST_DASHBOARD_ROOT  = Where to put source and build trees
#   CTEST_TEST_TIMEOUT    = Per-test timeout length
#   CTEST_TEST_ARGS       = ctest_test args (ex: PARALLEL_LEVEL 4)
#   CMAKE_MAKE_PROGRAM    = Path to "make" tool to use
#
# For Makefile generators the script may be executed from an
# environment already configured to use the desired compilers.
# Alternatively the environment may be set at the top of the script:
#
#   set(ENV{CC}  /path/to/cc)   # C compiler
#   set(ENV{CXX} /path/to/cxx)  # C++ compiler
#   set(ENV{FC}  /path/to/fc)   # Fortran compiler (optional)
#   set(ENV{LD_LIBRARY_PATH} /path/to/vendor/lib) # (if necessary)

#=============================================================================
# Copyright 2010-2012 Kitware, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the name of Kitware, Inc. nor the names of its contributors
#   may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

cmake_minimum_required(VERSION 2.8.2 FATAL_ERROR)

set(CTEST_PROJECT_NAME KWSys)
set(dashboard_user_home "$ENV{HOME}")

# Select the top dashboard directory.
if(NOT DEFINED dashboard_root_name)
  set(dashboard_root_name "My Tests")
endif()
if(NOT DEFINED CTEST_DASHBOARD_ROOT)
  get_filename_component(CTEST_DASHBOARD_ROOT "${CTEST_SCRIPT_DIRECTORY}/../${dashboard_root_name}" ABSOLUTE)
endif()

# Select the model (Nightly, Experimental).
if(NOT DEFINED dashboard_model)
  set(dashboard_model Nightly)
endif()
if(NOT "${dashboard_model}" MATCHES "^(Nightly|Experimental)$")
  message(FATAL_ERROR "dashboard_model must be Nightly or Experimental")
endif()

# Default to a Debug build.
if(NOT DEFINED CTEST_BUILD_CONFIGURATION)
  set(CTEST_BUILD_CONFIGURATION Debug)
endif()

# Choose CTest reporting mode.
if(NOT "${CTEST_CMAKE_GENERATOR}" MATCHES "Make")
  # Launchers work only with Makefile generators.
  set(CTEST_USE_LAUNCHERS 0)
elseif(NOT DEFINED CTEST_USE_LAUNCHERS)
  set(CTEST_USE_LAUNCHERS 1)
endif()

# Configure testing.
if(NOT CTEST_TEST_TIMEOUT)
  set(CTEST_TEST_TIMEOUT 1500)
endif()

# Select Git source to use.
if(NOT DEFINED KWSys_git_repo)
  set(KWSys_git_repo "git://public.kitware.com/KWSys.git")
endif()
if(NOT DEFINED KWSys_git_branch)
  set(KWSys_git_branch master)
endif()
if(NOT DEFINED dashboard_git_crlf)
  if(UNIX)
    set(dashboard_git_crlf false)
  else(UNIX)
    set(dashboard_git_crlf true)
  endif(UNIX)
endif()

# Select topic testing URLs.
if(NOT DEFINED KWSys_topics_repo)
  set(KWSys_topics_repo "http://review.source.kitware.com/p/KWSys")
endif()
if(NOT DEFINED KWSys_topics_url)
  set(KWSys_topics_url "http://review.source.kitware.com/static/Test-KWSys.txt")
endif()

# Look for a GIT command-line client.
if(NOT DEFINED CTEST_GIT_COMMAND)
  find_program(CTEST_GIT_COMMAND
    NAMES git git.cmd
    PATH_SUFFIXES Git/cmd Git/bin
    )
endif()
if(NOT CTEST_GIT_COMMAND)
  message(FATAL_ERROR "CTEST_GIT_COMMAND not available!")
endif()
execute_process(COMMAND ${CTEST_GIT_COMMAND} --version
                OUTPUT_VARIABLE git_version
                ERROR_QUIET
                OUTPUT_STRIP_TRAILING_WHITESPACE)
if (git_version MATCHES "^git version [0-9]")
  string(REPLACE "git version " "" git_version "${git_version}")
endif()
if("${git_version}" VERSION_LESS 1.6.6)
  message(FATAL_ERROR "CTEST_GIT_COMMAND must be Git >= 1.6.6, not:\n ${git_version}")
endif()

# Select a source directory name.
if(NOT DEFINED CTEST_SOURCE_DIRECTORY)
  if(DEFINED KWSys_source_name)
    set(CTEST_SOURCE_DIRECTORY ${CTEST_DASHBOARD_ROOT}/${KWSys_source_name})
  else()
    set(CTEST_SOURCE_DIRECTORY ${CTEST_DASHBOARD_ROOT}/KWSys)
  endif()
endif()

# Select a build directory name.
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  if(DEFINED KWSys_binary_name)
    set(CTEST_BINARY_DIRECTORY ${CTEST_DASHBOARD_ROOT}/${KWSys_binary_name})
  else()
    set(CTEST_BINARY_DIRECTORY ${CTEST_SOURCE_DIRECTORY}-build)
  endif()
endif()

# Disallow in-source builds.
if("${CTEST_SOURCE_DIRECTORY}" STREQUAL "${CTEST_BINARY_DIRECTORY}")
  message(FATAL_ERROR "In-source testing not supported.  "
    "Specify distinct CTEST_SOURCE_DIRECTORY and CTEST_BINARY_DIRECTORY.")
endif()

macro(dashboard_git)
  execute_process(
    COMMAND ${CTEST_GIT_COMMAND} ${ARGN}
    WORKING_DIRECTORY "${CTEST_SOURCE_DIRECTORY}"
    OUTPUT_VARIABLE dashboard_git_output
    ERROR_VARIABLE dashboard_git_output
    RESULT_VARIABLE dashboard_git_failed
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    )
endmacro()

# Delete source tree if it is incompatible with current VCS.
if(EXISTS ${CTEST_SOURCE_DIRECTORY})
  if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}/.git")
    set(vcs_refresh "because it is not managed by git.")
  else()
    dashboard_git(reset --hard)
    if(dashboard_git_failed)
      set(vcs_refresh "because its .git may be corrupted.")
    endif()
  endif()
  if(vcs_refresh AND "${CTEST_SOURCE_DIRECTORY}" MATCHES "/KWSys[^/]*")
    message("Deleting source tree\n  ${CTEST_SOURCE_DIRECTORY}\n${vcs_refresh}")
    file(REMOVE_RECURSE "${CTEST_SOURCE_DIRECTORY}")
  endif()
endif()

# Support initial checkout if necessary.
if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}"
    AND NOT DEFINED CTEST_CHECKOUT_COMMAND)
  # Generate an initial checkout script.
  get_filename_component(_name "${CTEST_SOURCE_DIRECTORY}" NAME)
  set(ctest_checkout_script ${CTEST_DASHBOARD_ROOT}/${_name}-init.cmake)
  file(WRITE ${ctest_checkout_script} "# git repo init script for ${_name}
execute_process(
  COMMAND \"${CTEST_GIT_COMMAND}\" clone -n -b ${KWSys_git_branch} -- \"${KWSys_git_repo}\"
          \"${CTEST_SOURCE_DIRECTORY}\"
  )
if(EXISTS \"${CTEST_SOURCE_DIRECTORY}/.git\")
  execute_process(
    COMMAND \"${CTEST_GIT_COMMAND}\" config core.autocrlf ${dashboard_git_crlf}
    WORKING_DIRECTORY \"${CTEST_SOURCE_DIRECTORY}\"
    )
  execute_process(
    COMMAND \"${CTEST_GIT_COMMAND}\" checkout
    WORKING_DIRECTORY \"${CTEST_SOURCE_DIRECTORY}\"
    )
endif()
")
  set(CTEST_CHECKOUT_COMMAND "\"${CMAKE_COMMAND}\" -P \"${ctest_checkout_script}\"")
elseif(EXISTS "${CTEST_SOURCE_DIRECTORY}/.git")
  # Start on the branch to be tested.
  dashboard_git(rev-parse --verify -q refs/heads/${KWSys_git_branch})
  if(dashboard_git_failed)
    dashboard_git(checkout -b ${KWSys_git_branch} origin/${KWSys_git_branch})
  else()
    dashboard_git(checkout ${KWSys_git_branch})
  endif()
  if(dashboard_git_failed)
    message(FATAL_ERROR "Failed to checkout branch ${KWSys_git_branch}:\n${dashboard_git_output}")
  endif()
endif()

# We always use CMake for configuration.
unset(CTEST_CONFIGURE_COMMAND)

#-----------------------------------------------------------------------------

# Send the main script as a note.
list(APPEND CTEST_NOTES_FILES
  "${CTEST_SCRIPT_DIRECTORY}/${CTEST_SCRIPT_NAME}"
  "${CMAKE_CURRENT_LIST_FILE}"
  )

# Check for required variables.
foreach(req
    CTEST_CMAKE_GENERATOR
    CTEST_SITE
    CTEST_BUILD_NAME
    )
  if(NOT DEFINED ${req})
    message(FATAL_ERROR "The containing script must set ${req}")
  endif()
endforeach(req)

# Print summary information.
set(vars "")
foreach(v
    CTEST_SITE
    CTEST_BUILD_NAME
    CTEST_SOURCE_DIRECTORY
    CTEST_BINARY_DIRECTORY
    CTEST_CMAKE_GENERATOR
    CTEST_BUILD_CONFIGURATION
    CTEST_GIT_COMMAND
    CTEST_CHECKOUT_COMMAND
    CTEST_SCRIPT_DIRECTORY
    CTEST_USE_LAUNCHERS
    )
  set(vars "${vars}  ${v}=[${${v}}]\n")
endforeach(v)
message("Dashboard script configuration:\n${vars}\n")

# Avoid non-ascii characters in tool output.
set(ENV{LC_ALL} C)

# Helper macro to write the initial cache.
macro(write_cache)
  set(cache_build_type "")
  set(cache_make_program "")
  if(CTEST_CMAKE_GENERATOR MATCHES "Make")
    set(cache_build_type CMAKE_BUILD_TYPE:STRING=${CTEST_BUILD_CONFIGURATION})
    if(CMAKE_MAKE_PROGRAM)
      set(cache_make_program CMAKE_MAKE_PROGRAM:FILEPATH=${CMAKE_MAKE_PROGRAM})
    endif()
  endif()
  set(cache_git_executable "")
  file(WRITE ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt "
SITE:STRING=${CTEST_SITE}
BUILDNAME:STRING=${CTEST_BUILD_NAME}
CTEST_USE_LAUNCHERS:BOOL=${CTEST_USE_LAUNCHERS}
DART_TESTING_TIMEOUT:STRING=${CTEST_TEST_TIMEOUT}
${cache_build_type}
${cache_make_program}
${KWSys_cache}
")
endmacro(write_cache)

macro(dashboard_run_KWSys)
  set(ENV{HOME} "${dashboard_user_home}")
  message("Clearing build tree...")
  ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
  ctest_start(${dashboard_model})
  write_cache()
  ctest_update(RETURN_VALUE count)
  set(CTEST_CHECKOUT_COMMAND) # checkout on first call only
  message("Found ${count} changed files")
  ctest_configure()
  ctest_read_custom_files(${CTEST_BINARY_DIRECTORY})
  ctest_build()
  ctest_test(${CTEST_TEST_ARGS})
  if(dashboard_do_coverage)
    ctest_coverage()
  endif()
  if(dashboard_do_memcheck)
    ctest_memcheck()
  endif()
  if(NOT dashboard_no_submit)
    ctest_submit()
  endif()
endmacro()

#-----------------------------------------------------------------------------

# Run the main dashboard.
dashboard_run_KWSys()

# Switch to experimental mode to test topic branches.
set(dashboard_model Experimental)
set(dashboard_build_name ${CTEST_BUILD_NAME})
dashboard_git(branch -f experimental)
dashboard_git(checkout experimental)

# Download the topics file.
get_filename_component(_name "${CTEST_SOURCE_DIRECTORY}" NAME)
set(topics_file ${CTEST_DASHBOARD_ROOT}/${_name}-topics.txt)
file(DOWNLOAD "${KWSys_topics_url}" "${topics_file}" INACTIVITY_TIMEOUT 5 STATUS status LOG log)
list(GET status 0 failed)
if(failed)
  message(WARNING "Failed to download\n ${KWSys_topics_url}\n${status}\n${log}")
  return()
endif()

# Parse the topics file.
set(topic_heads "")
set(topic_refs "")
file(STRINGS "${topics_file}" topic_lines LIMIT_COUNT 50 LIMIT_INPUT 65536)
foreach(line ${topic_lines})
  if("${line}" MATCHES "^([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+) ([A-Za-z0-9/._-]+) ([A-Za-z0-9/._-]+)$")
    set(head ${CMAKE_MATCH_1})
    set(ref_${head} ${CMAKE_MATCH_2})
    set(topic_${head} ${CMAKE_MATCH_3})
    list(APPEND topic_heads ${head})
    list(APPEND topic_refs ${ref_${head}})
  else()
    message(WARNING "Skipping unrecognized line:\n ${line}\n")
  endif()
endforeach()

# Fetch the topics.
dashboard_git(fetch ${KWSys_topics_repo} ${topic_refs})
if(dashboard_git_failed)
  message(WARNING "Failed to fetch topics:\n${dashboard_git_output}\n")
endif()

# Run an experimental build for each topic head.
foreach(head ${topic_heads})
  dashboard_git(reset --hard ${KWSys_git_branch})

  dashboard_git(rev-parse --verify -q --short=5 ${head})
  if(dashboard_git_failed)
    message(WARNING "Skipping commit '${head}' that does not exist!")
  else()
    set(topic ${topic_${head}})
    set(short ${dashboard_git_output})
    set(CTEST_BUILD_NAME ${topic}-g${short}+${dashboard_build_name})
    set(CTEST_GIT_UPDATE_CUSTOM ${CTEST_GIT_COMMAND} reset --hard ${head})
    dashboard_run_KWSys()
  endif()
endforeach()
