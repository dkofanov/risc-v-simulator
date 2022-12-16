
#include "common.h"

namespace sim {
    void State::runSimulation() {
        memory.loadELF(elfFileName);
        cpu.runPipeline();
    };

} // namespace sim
