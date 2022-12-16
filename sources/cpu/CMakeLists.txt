
set(SOURCES main.cpp cpu.cpp)
add_executable(executor ${SOURCES})
target_include_directories(executor PUBLIC ${PROJECT_BINARY_DIR} 
                                           ${PROJECT_SOURCE_DIR}/include)
