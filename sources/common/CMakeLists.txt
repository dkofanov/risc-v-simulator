
set(SOURCES main.cpp common.cpp)
add_executable(simulator ${SOURCES})
target_include_directories(simulator PUBLIC ${PROJECT_BINARY_DIR} 
                                           ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(simulator PUBLIC cpu memory)
