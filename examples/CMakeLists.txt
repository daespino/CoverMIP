# We define an executable for each 'test.*.cpp' source file.
# Note that because the top-level CMakeList.txt uses 'include(CTest)' and
# 'include(CMake/Tests.cmake)' ; we also get the target 'all_tests'; which
# builds and run all tests using CTest.
file(GLOB examples_src "*.c")

# Testing sources and binaries.
project(GurobiExamples)

foreach(src IN ITEMS ${examples_src})
    string(REGEX REPLACE "^.*\/" "" file ${src})
    string(REPLACE ".c" "" binary ${file})
    add_executable(${binary} ${src})
    target_include_directories(${binary} PUBLIC ${GUROBI_INC_DIR})
		target_link_libraries(${binary} PUBLIC ${GUROBI_STATIC_LIBRARY})
    message(STATUS "Adding example ${binary}")
endforeach()

