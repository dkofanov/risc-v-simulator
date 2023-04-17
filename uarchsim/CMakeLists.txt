find_package(verilator)

set(DRIVER_SRC ${CMAKE_CURRENT_SOURCE_DIR}/driver.cpp)
set(TOP_V ${CMAKE_CURRENT_SOURCE_DIR}/verilog/top.v)
set(OUT_EXEC ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/uarchsim)


add_custom_target(uarchsim)
add_custom_command(TARGET uarchsim
    COMMAND verilator -Wall --cc ${TOP_V} --exe ${DRIVER_SRC} --build -o ${OUT_EXEC}
)

