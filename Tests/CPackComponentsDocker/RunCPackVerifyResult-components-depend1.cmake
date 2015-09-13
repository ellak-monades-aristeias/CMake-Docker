if(NOT CPackComponentsDOCKER_SOURCE_DIR)
  message(FATAL_ERROR "CPackComponentsDOCKER_SOURCE_DIR not set")
endif()

include(${CPackComponentsDOCKER_SOURCE_DIR}/RunCPackVerifyResult.cmake)


# expected results
set(expected_file_mask "${CPackComponentsDOCKER_BINARY_DIR}/MyLib-*/Dockerfile")
set(expected_count 1)


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
