# Required by CMake.
cmake_minimum_required(VERSION 3.22)

# The Compiler must be set BEFORE the Project declaration, otherwise, it will create an endless loop
#
# Ad-hoc setup for mansci's linux
cmake_host_system_information(RESULT HOSTNAME QUERY HOSTNAME)
if("${HOSTNAME}" STREQUAL "mansci.public" OR
    "${HOSTNAME}" MATCHES "alicanto01")
    SET(CMAKE_CXX_COMPILER "/opt/rh/devtoolset-11/root/usr/bin/g++")
    SET(CMAKE_C_COMPILER "/opt/rh/devtoolset-11/root/usr/bin/gcc")
endif()

# on mansci2 we don't build with arch=native, because the head node is
# different that the nodes
set(NO_NATIVE_ARCH ("$HOSTNAME" MATCHES "mansci2"))

message(STATUS "Running in ${HOSTNAME}")
set(CMAKE_SKIP_BUILD_RPATH true)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH true)

# Check if ccache is installed
find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
  message(STATUS "Found ccache")
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif(CCACHE_FOUND)

# Mark all exported symbols as hidden by default
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Use the latest available standards in C/C++ code
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED  ON)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set the project name and version.
project(CoverMIP VERSION 0.1)

message(STATUS "Compiling in ${CMAKE_SYSTEM_NAME} version ${CMAKE_SYSTEM_VERSION} using ${CMAKE_CXX_COMPILER_ID}")

message(STATUS "Using ${CMAKE_CXX_COMPILER} as C++ compiler.")
message(STATUS "Using ${CMAKE_C_COMPILER} as C compiler.")
message(STATUS " ")
message(STATUS "Entering ${PROJECT_NAME}")
message(STATUS "Compiling in ${CMAKE_BUILD_TYPE} mode!!!")
string( TOLOWER "${CMAKE_BUILD_TYPE}" build_type )

if(ASAN)
  message(STATUS "Address sanitizer enabled")
  add_compile_options(-fsanitize=address -fsanitize=leak -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address -fsanitize=leak)
endif(ASAN)

if(MSAN)
  message(STATUS "Memory sanitizer enabled")
  add_compile_options(-fsanitize=memory)
  add_link_options(-fsanitize=memory)
endif(MSAN)

if(TSAN)
  message(STATUS "Thread sanitizer enabled")
  add_compile_options(-fsanitize=thread)
  add_link_options(-fsanitize=thread)
endif(TSAN)

if(UBSAN)
  message(STATUS "Undefined behavior sanitizer enabled")
  add_compile_options(-fsanitize=undefined)
  add_link_options(-fsanitize=undefined)
endif(UBSAN)


# Include CTest
include(CTest)

# Include flags definition for compiler.
include(Flags.cmake)

# Declare the target 'all_tests' which builds and execute (using CTest) all tests.
# Note that tests are expected to be defined following 'googletest' macros and
# functions.
include(Tests.cmake)
alicanto_prepare_to_test()

if(NOT(build_type MATCHES "debug") AND NOT(build_type MATCHES "release") AND NOT(build_type MATCHES "relwithdebinfo"))
  message(FATAL_ERROR "Check your setting of CMAKE_BUILD_TYPE, only \"Debug\", \"Release\" and \"RelWithDebInfo\" are supported.\nUse \"cmake -DCMAKE_BUILD_TYPE=<build type>\" to set the appropiate build type.")
endif()

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
  SET(LINUX TRUE)
else()
  SET(LINUX FALSE)
endif()

if(build_type MATCHES "debug")
    set(CXX_BUILD_FLAGS "${CMAKE_CXX_FLAGS_DEBUG}")
elseif(build_type MATCHES "release")
    set(C_BUILD_FLAGS "${CMAKE_C_FLAGS_RELEASE}")
    set(CXX_BUILD_FLAGS "${CMAKE_CXX_FLAGS_RELEASE}")
elseif(build_type MATCHES "relwithdebinfo")
    set(C_BUILD_FLAGS "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
    set(CXX_BUILD_FLAGS "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
endif()

message(STATUS "Using the following C base flags:  ${CMAKE_C_FLAGS}")
message(STATUS "Using the following C extra flags: ${C_BUILD_FLAGS}")
message(STATUS "Using the following C++ base flags:  ${CMAKE_CXX_FLAGS}")
message(STATUS "Using the following C++ extra flags: ${CXX_BUILD_FLAGS}")

# Colors in errors if possible
check_cxx_compiler_flag( -fcolor-diagnostics COLOR_DIAGNOSTICS_FLAG_SUPPORTED)
if (COLOR_DIAGNOSTICS_FLAG_SUPPORTED)
    add_compile_options (-fcolor-diagnostics)
else()
    check_cxx_compiler_flag( -fdiagnostics-color COLOR_DIAGNOSTICS_FLAG_SUPPORTED2)
    if (COLOR_DIAGNOSTICS_FLAG_SUPPORTED2)
        add_compile_options (-fdiagnostics-color)
    endif()
endif()

# Declare bz-lib
add_library(cover_lib STATIC)
set_target_properties(cover_lib PROPERTIES LINKER_LANGUAGE CXX)

include(SolverGurobi.cmake)

# Subdirectories must be added considering which depends on others. Those that depends
# on others must be placed at the end, those without local dependencies, at the
# beginning, that way, the chain of dependencies will be built in the proper order
# add_subdirectory(External)       # No local dependencies
add_subdirectory(src)       # No local dependencies
add_subdirectory(examples)

if(LINUX OR APPLE)
	target_link_libraries(cover_lib PUBLIC ${CMAKE_THREAD_LIBS_INIT})

	if(build_type MATCHES "relwithdebinfo")
		if(UNWIND-X86_64_FOUND)
			target_link_libraries(cover_lib PUBLIC ${UNWIND-X86_64})
		endif()
		if(GPERF_CPU_FOUND)
			target_link_libraries(cover_lib PUBLIC ${GPERF_CPU})
		endif()
		if(GPERF_MEM_FOUND)
			target_link_libraries(cover_lib PUBLIC ${GPERF_MEM})
		endif()
	endif()

elseif(WIN32 AND MSVC)
	# This compile definition is necessary to prevent the usage of "__declspec(dllimport)" when building the static library.
	target_compile_definitions(cover_lib PUBLIC UTILS_STATIC)

endif()

