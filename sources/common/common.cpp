
#include "cpu.h"
#include "common.h"

namespace sim {
    void State::runSimulation() {
        cpu.runPipeline();
    };

    State::State(std::string& elfFileName) {
        memory.loadELF(elfFileName);
    }

} // namespace sim
