# Macros and definitions to add test targets. The intent is to use
# Google Test to write tests, and to use `ctest` to run all tests.
# Note that these must be macros and not functions, so the commands are
# `inlined` in the source file.

# Target `all_tests` will build and run all tests.
if (NOT TARGET all_tests)
add_custom_target(all_tests COMMAND ${CMAKE_CTEST_COMMAND} -j 14)
endif()

# We define a list of libraries to link for tests called ADITIONAL_TEST_LDPATHS.
set(ADDITIONAL_TEST_LDPATHS "$ENV{LD_LIBRARY_PATH}")
foreach(libdir IN ITEMS ${CMAKE_LIBRARY_PATH})
  string(APPEND ADDITIONAL_TEST_LDPATHS ":${libdir}")
endforeach()

# Function that fetch (if necesary) needed packages and declare variables
# needed to add test targets.
macro(alicanto_prepare_to_test)
  include(FetchContent)
  set(FETCHCONTENT_QUIET OFF)
  # Can change actual location or try several paths in a list.
  if (DEFINED ENV{CMP_GTEST_DIR}
      AND EXISTS "$ENV{CMP_GTEST_DIR}"
      AND EXISTS "$ENV{CMP_GTEST_DIR}/CMakeLists.txt"
      AND EXISTS "$ENV{CMP_GTEST_DIR}/googletest"
      AND EXISTS "$ENV{CMP_GTEST_DIR}/googletest/CMakeLists.txt"
      AND EXISTS "$ENV{CMP_GTEST_DIR}/googlemock"
      AND EXISTS "$ENV{CMP_GTEST_DIR}/googlemock/CMakeLists.txt")
    # Fetch from local source.
    FetchContent_Declare(
            googletest
            SOURCE_DIR $ENV{CMP_GTEST_DIR})
    message(STATUS "Using local googletest source $ENV{CMP_GTEST_DIR}")
  else()
    # Fetch from GIT at a given git-tag
    FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG v1.15.2)
    message(STATUS "Using remote googletest tag v1.15.2")
  endif()
  # For Windows: Prevent overriding the parent project's compiler/linker settings
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(googletest)
  if(NOT googletest_POPULATED)
    FetchContent_Populate(googletest)
    add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR})
  endif()
  include(GoogleTest)
  if(NOT DEFINED google_test_added_to_system_includes)
    FetchContent_GetProperties(googletest SOURCE_DIR GTestSource)
    list(APPEND gtest_includes ${GTestSource}/googletest/include)
    list(APPEND gtest_includes ${GTestSource}/googlemock/include)
    set(google_test_added_to_system_includes true)
  endif()
endmacro()

# Adds the given `binary` to the lists of tests to be run; which should depend
# on `source` to be built; setting includes and dependencies needed for
# Google Test, andd adding run-time paths in `ADDITIONAL_TEST_LDPATHS` to the
# target. Following arguments are treated as link libraries to be added to the
# binary.
macro(alicanto_add_test source)
  # Ensure we have at least a source argument.
  if (${ARGC} LESS 1)
    message(ERROR "source argument required")
  endif()
  # Issue #1961, problem linking binaries in windows.
  if(NOT WIN32)
    string(REGEX REPLACE "^.*\/" "" file ${source})
    string(REPLACE ".cpp" "" binary ${file})
    add_executable(${binary} ${source})
    message(STATUS "Adding test ${binary}")
    # Always depend on google test.
    target_link_libraries(${binary} GTest::gmock_main)
    # Add all following arguments as libraries to the target.
    set(alicanto_test_args "${ARGN}")
    foreach(arg IN LISTS alicanto_test_args) 
      target_link_libraries(${binary} ${arg})
    endforeach()
    add_dependencies(all_tests ${binary})
    foreach(include_dir IN ITEMS ${gtest_includes})
      target_include_directories(${binary} SYSTEM BEFORE PRIVATE ${include_dir})
    endforeach()
    if(UNIX)
      set_tests_properties(${test_list} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${ADDITIONAL_TEST_LDPATHS}")
      set_target_properties(${binary} PROPERTIES ENVIRONMENT "LD_LIBRARY_PATH=${ADDITIONAL_TEST_LDPATHS}")
    elseif(WIN32 AND MSVC)
      set_tests_properties(${test_list} PROPERTIES ENVIRONMENT "PATH=${ADDITIONAL_TEST_LDPATHS}")
    endif()
    gtest_discover_tests(${binary} TEST_LIST test_list)
    # Not needed, CTest dectes the individual google-tests automatically.
    # add_test(NAME "T${binary}" COMMAND ${binary})
  endif()
endmacro()
