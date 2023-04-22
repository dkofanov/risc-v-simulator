find_package(verilator)

set(DRIVER_SRC ${CMAKE_CURRENT_SOURCE_DIR}/driver.cpp)
set(TOP_V ${CMAKE_CURRENT_SOURCE_DIR}/verilog/top.v)
set(VERILATOR_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/obj_dir)
set(OUT_EXEC ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/uarchsim)


add_custom_target(uarchsim)
add_custom_command(TARGET uarchsim
    COMMAND verilator -Wall --cc ${TOP_V} --exe ${DRIVER_SRC} --build -o ${OUT_EXEC} -I${CMAKE_CURRENT_SOURCE_DIR}/verilog -I${CMAKE_CURRENT_BINARY_DIR}/verilog --Mdir ${VERILATOR_GEN_DIR} --unroll-count 256
    COMMAND rm -rf ${VERILATOR_GEN_DIR}/*
)

add_subdirectory(verilog/core)
