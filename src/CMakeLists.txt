target_sources(cover_lib PUBLIC
   cover_constants.cpp
   )

target_sources(cover_lib PUBLIC
   cover_constants.h
   )

target_include_directories(cover_lib PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_include_directories(cover_lib PUBLIC ${GUROBI_INC_DIR})
target_link_libraries(cover_lib PUBLIC ${GUROBI_STATIC_LIBRARY})

add_executable(cover example.cpp)
target_include_directories(cover PUBLIC .)
target_link_libraries(cover PUBLIC cover_lib)
