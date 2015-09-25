# prevent older policies from interfearing with this script
cmake_policy(PUSH)
cmake_policy(VERSION ${CMAKE_VERSION})


include(CMakeParseArguments)

message(STATUS "=============================================================================")
message(STATUS "CTEST_FULL_OUTPUT (Avoid ctest truncation of output)")
message(STATUS "")

if(NOT CPackComponentsDOCKER_BINARY_DIR)
  message(FATAL_ERROR "CPackComponentsDOCKER_BINARY_DIR not set")
endif()

if(NOT CPackGen)
  message(FATAL_ERROR "CPackGen not set")
endif()

message("CMAKE_CPACK_COMMAND = ${CMAKE_CPACK_COMMAND}")
if(NOT CMAKE_CPACK_COMMAND)
  message(FATAL_ERROR "CMAKE_CPACK_COMMAND not set")
endif()

if(NOT CPackDOCKERConfiguration)
  message(FATAL_ERROR "CPackDOCKERConfiguration not set")
endif()

# run cpack with some options and returns the list of files generated
# -output_expected_file: list of files that match the pattern
function(run_cpack output_expected_file CPack_output_parent CPack_error_parent)
  set(options )
  set(oneValueArgs "EXPECTED_FILE_MASK" "CONFIG_VERBOSE")
  set(multiValueArgs "CONFIG_ARGS")
  cmake_parse_arguments(run_cpack_docker "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )


  # clean-up previously CPack generated files
  if(${run_cpack_docker_EXPECTED_FILE_MASK})
    file(GLOB expected_file "${${run_cpack_docker_EXPECTED_FILE_MASK}}")
    if (expected_file)
      file(REMOVE "${expected_file}")
    endif()
  endif()

  message("config_args = ${run_cpack_docker_CONFIG_ARGS}")
  message("config_verbose = ${run_cpack_docker_CONFIG_VERBOSE}")
  execute_process(COMMAND ${CMAKE_CPACK_COMMAND} ${run_cpack_docker_CONFIG_VERBOSE} -G ${CPackGen} ${run_cpack_docker_CONFIG_ARGS}
      RESULT_VARIABLE CPack_result
      OUTPUT_VARIABLE CPack_output
      ERROR_VARIABLE CPack_error
      WORKING_DIRECTORY ${CPackComponentsDOCKER_BINARY_DIR})

  set(${CPack_output_parent} ${CPack_output} PARENT_SCOPE)
  set(${CPack_error_parent}  ${CPack_error} PARENT_SCOPE)

  if (CPack_result)
    message(FATAL_ERROR "error: CPack execution went wrong!, CPack_output=${CPack_output}, CPack_error=${CPack_error}")
  else ()
    message(STATUS "CPack_output=${CPack_output}")
    message(STATUS "CPack_error=${CPack_error}")
  endif()


  if(run_cpack_docker_EXPECTED_FILE_MASK)
    file(GLOB _output_expected_file "${run_cpack_docker_EXPECTED_FILE_MASK}")
    set(${output_expected_file} "${_output_expected_file}" PARENT_SCOPE)
  endif()
endfunction()

# this function runs docker on a .dockerfile and returns its output
function(run_docker docker_output docker_result)
  set(${docker_output} "" PARENT_SCOPE)

  find_program(DOCKER_EXECUTABLE docker)
  if(DOCKER_EXECUTABLE)
    set(options "")
    set(oneValueArgs "FILENAME")
    set(multiValueArgs "")
    cmake_parse_arguments(run_docker "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT run_docker_FILENAME)
      message(FATAL_ERROR "error: run_docker needs FILENAME to be set")
    endif()

    get_filename_component(run_docker_TAGNAME ${run_docker_FILENAME} NAME)
    string(REPLACE ".dockerfile" "" run_docker_TAGNAME ${run_docker_TAGNAME})
    string(TOLOWER ${run_docker_TAGNAME} run_docker_TAGNAME)

    execute_process(
      COMMAND ${DOCKER_EXECUTABLE} build --file="${run_docker_FILENAME}" --tag="${run_docker_TAGNAME}" .
      WORKING_DIRECTORY "${CPACK_TOPLEVEL_DIRECTORY}"
      OUTPUT_VARIABLE DOCKER_OUTPUT 
      RESULT_VARIABLE DOCKER_RESULT
      ERROR_VARIABLE  DOCKER_ERROR
    )

    set(${docker_output} "${run_docker_TAGNAME}" PARENT_SCOPE)
    set(${docker_result} "${DOCKER_RESULT}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "run_docker called without docker executable being present")
  endif()
endfunction()

cmake_policy(POP)
