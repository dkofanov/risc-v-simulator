#pragma once

#include "cpu.h"
#include "memory.h"

namespace sim {

class State {
    sim::CPU cpu;
    sim::Memory memory;
    void runSimulation();
};

} // namespace sim
