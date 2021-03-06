include(RunCMake)

run_cmake(XcodeFileType)
run_cmake(XcodeAttributeGenex)
run_cmake(XcodeAttributeGenexError)
run_cmake(XcodeObjectNeedsQuote)
if (NOT XCODE_VERSION VERSION_LESS 6)
  run_cmake(XcodePlatformFrameworks)
endif()

# Use a single build tree for a few tests without cleaning.

if(NOT XCODE_VERSION VERSION_LESS 5)
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/XcodeBundlesOSX-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  set(RunCMake_TEST_OPTIONS "-DTEST_IOS=OFF")

  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(XcodeBundles)
  run_cmake_command(XcodeBundles-build ${CMAKE_COMMAND} --build .)

  unset(RunCMake_TEST_BINARY_DIR)
  unset(RunCMake_TEST_NO_CLEAN)
  unset(RunCMake_TEST_OPTIONS)

  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/XcodeBundlesIOS-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  set(RunCMake_TEST_OPTIONS "-DTEST_IOS=ON")

  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")

  run_cmake(XcodeBundles)
  run_cmake_command(XcodeBundles-build ${CMAKE_COMMAND} --build .)

  unset(RunCMake_TEST_BINARY_DIR)
  unset(RunCMake_TEST_NO_CLEAN)
  unset(RunCMake_TEST_OPTIONS)
endif()

if(NOT XCODE_VERSION VERSION_LESS 7)
  set(RunCMake_TEST_OPTIONS "-DCMAKE_TOOLCHAIN_FILE=${RunCMake_SOURCE_DIR}/osx.cmake")
  run_cmake(XcodeTbdStub)
  unset(RunCMake_TEST_OPTIONS)
endif()
