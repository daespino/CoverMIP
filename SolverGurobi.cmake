if(NOT GUROBI_DIR AND NOT GUROBI_VERSION)
  set(local_dir "/Library/gurobi1203/macos_universal2")
  if (EXISTS ${local_dir}
      AND EXISTS "${local_dir}/include/gurobi_c.h"
      AND EXISTS "${local_dir}/lib")
    set(GUROBI_DIR ${local_dir})
    set(GUROBI_VERSION 120)
  else()
    set(local_dir "/opt/gurobi1300/linux64")
    if (EXISTS ${local_dir}
        AND EXISTS "${local_dir}/include/gurobi_c.h"
        AND EXISTS "${local_dir}/lib")
      set(GUROBI_DIR ${local_dir})
      set(GUROBI_VERSION 130)
    endif()
  endif()
endif()

#Define directories where GUROBI should be searched for
if(NOT GUROBI_DIR)
	message(WARNING "GUROBI not defined.")
	set(GUROBI_FOUND 0 CACHE STRING "GUROBI not defined" FORCE)
	return()
endif()

if(NOT GUROBI_VERSION)
	message(WARNING "GUROBI_VERSION not defined.")
	set(GUROBI_FOUND 0 CACHE STRING "GUROBI not defined" FORCE)
	return()
endif()

set (GUROBI_INC_DIR "${GUROBI_DIR}/include" CACHE PATH "Include directory of GUROBI" FORCE)

# Check GUROBI is in fact installed where it should be
if(
	NOT IS_DIRECTORY "${GUROBI_INC_DIR}" OR
	NOT EXISTS "${GUROBI_INC_DIR}/gurobi_c.h")
	set(GUROBI_FOUND 0 CACHE STRING "GUROBI not defined" FORCE)
	message(FATAL_ERROR "GUROBI directory is incorrectly defined.")
endif()

# Linux, MacOSX
# Gurobi only provides the dynamic library for the C interface.
if(LINUX OR APPLE)
	set (GUROBI_STATIC_LIB_DIR "${GUROBI_DIR}/lib" CACHE PATH "Static library directory of GUROBI" FORCE)
	set (GUROBI_SHARED_LIB_DIR "${GUROBI_DIR}/lib" CACHE PATH "Shared library directory of GUROBI" FORCE)

	if(
		(LINUX AND NOT EXISTS "${GUROBI_SHARED_LIB_DIR}/libgurobi${GUROBI_VERSION}.so") OR
		(APPLE AND NOT EXISTS "${GUROBI_SHARED_LIB_DIR}/libgurobi${GUROBI_VERSION}.dylib"))
		set(GUROBI_FOUND 0 CACHE STRING "GUROBI not found" FORCE)
		message(FATAL_ERROR "GUROBI not found.")
	endif()
	set(GUROBI_FOUND 1 CACHE STRING "GUROBI found" FORCE)
	#find_library(GUROBI_STATIC_LIBRARY gurobi_c++ PATH ${GUROBI_STATIC_LIB_DIR})
	# We set the static library as the shared library to avoid having to introduce many "if's" in
	# the rest of the CMakeLists.txt files inside the modules. Just let them believe they are using the static library.
	# Also, if in the future GUROBI starts supporting the static library, it's just a matter to modify this line
	find_library(GUROBI_STATIC_LIBRARY gurobi${GUROBI_VERSION} PATH ${GUROBI_SHARED_LIB_DIR})
	find_library(GUROBI_SHARED_LIBRARY gurobi${GUROBI_VERSION} PATH ${GUROBI_SHARED_LIB_DIR})
# Windows, Gurobi only provides the dynamic library on Windows, see the CPLEX case for the detailed explanation
elseif(WIN32 AND MSVC)
	set (GUROBI_STATIC_LIB_DIR "${GUROBI_DIR}/lib" CACHE PATH "Static library directory of GUROBI" FORCE)
#		set (GUROBI_SHARED_LIB_DIR "${GUROBI_DIR}/bin" CACHE PATH "Shared library directory of GUROBI" FORCE)
	set (GUROBI_SHARED_LIB_DIR "${GUROBI_DIR}/lib" CACHE PATH "Shared library directory of GUROBI" FORCE)
	if(NOT EXISTS "${GUROBI_STATIC_LIB_DIR}/gurobi${GUROBI_VERSION}.lib")
		set(GUROBI_FOUND 0 CACHE STRING "GUROBI not found" FORCE)
		message(FATAL_ERROR "GUROBI not found.")
	endif()
		set(GUROBI_FOUND 1 CACHE STRING "GUROBI found" FORCE)
		find_library(GUROBI_STATIC_LIBRARY gurobi${GUROBI_VERSION} PATH ${GUROBI_STATIC_LIB_DIR})
		find_library(GUROBI_SHARED_LIBRARY gurobi${GUROBI_VERSION} PATH ${GUROBI_SHARED_LIB_DIR})
else()
	set(GUROBI_FOUND 0 CACHE STRING "GUROBI not found" FORCE)
	message(WARNING "GUROBI can be defined only in MacOSX, Linux or Windows. Current system is ${CMAKE_SYSTEM_NAME}")
endif()
if(GUROBI_FOUND)
	add_compile_definitions(CMP_GUROBI)
	message(STATUS "GUROBI found")
	message(STATUS "GUROBI_INC_DIR set to ${GUROBI_INC_DIR}")
	message(STATUS "GUROBI_STATIC_LIB_DIR set to ${GUROBI_STATIC_LIB_DIR}")
	message(STATUS "GUROBI_SHARED_LIB_DIR set to ${GUROBI_SHARED_LIB_DIR}")
	message(STATUS "GUROBI_STATIC_LIBRARY set to ${GUROBI_STATIC_LIBRARY}")
	message(STATUS "GUROBI_SHARED_LIBRARY set to ${GUROBI_SHARED_LIBRARY}")

  string(APPEND ADDITIONAL_TEST_LDPATHS ":${GUROBI_SHARED_LIB_DIR}")
endif()
