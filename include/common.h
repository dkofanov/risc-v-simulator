#pragma once

#include "cpu.h"
#include "memory.h"

namespace sim {

class State {
    std::string elfFileName;
    sim::CPU cpu;
    sim::Memory memory;
    void runSimulation();
};

} // namespace sim
