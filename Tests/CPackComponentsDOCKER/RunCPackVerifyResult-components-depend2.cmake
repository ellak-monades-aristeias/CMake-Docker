if(NOT CPackComponentsDOCKER_SOURCE_DIR)
  message(FATAL_ERROR "CPackComponentsDOCKER_SOURCE_DIR not set")
endif()

include(${CPackComponentsDOCKER_SOURCE_DIR}/RunCPackVerifyResult.cmake)


# expected results
set(expected_file_mask "${CPackComponentsDOCKER_BINARY_DIR}/MyLib-*.dockerfile")
set(expected_count 3)


set(actual_output)
run_cpack(actual_output
          CPack_output
          CPack_error
          EXPECTED_FILE_MASK "${expected_file_mask}"
          CONFIG_ARGS ${config_args}
          CONFIG_VERBOSE ${config_verbose})


if(NOT actual_output)
  message(STATUS "expected_count='${expected_count}'")
  message(STATUS "expected_file_mask='${expected_file_mask}'")
  message(STATUS "actual_output_files='${actual_output}'")
  message(FATAL_ERROR "error: expected_files do not exist: CPackComponentsDOCKER test fails. (CPack_output=${CPack_output}, CPack_error=${CPack_error}")
endif()

list(LENGTH actual_output actual_count)
if(NOT actual_count EQUAL expected_count)
  message(STATUS "actual_count='${actual_count}'")
  message(FATAL_ERROR "error: expected_count=${expected_count} does not match actual_count=${actual_count}: CPackComponents test fails. (CPack_output=${CPack_output}, CPack_error=${CPack_error})")
endif()

find_program(DOCKER_EXECUTABLE docker)
if(DOCKER_EXECUTABLE)
  set(docker_output_errors_all "")
  foreach(_f IN LISTS actual_output)
    run_docker(run_docker_output 
               run_docker_result
               FILENAME "${_f}")
    file(WRITE "${_f}.log" ${run_docker_output})
    if(run_docker_result)
      message(FATAL_ERROR "Error while running the dockerfile")
    endif()
    delete_docker(delete_docker_output
                  delete_docker_result
                  FILENAME "${_f}")
    file(APPEND "${_f}.log" ${delete_docker_output})
    if(delete_docker_result)
      message(FATAL_ERROR "Error while deleting the docker image")
    endif()
  endforeach()
endif()