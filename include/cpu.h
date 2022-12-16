#pragma once

#include <cstdint>
#include <array>

constexpr int regNum = 32;

namespace sim {

class Register {
    // all registers are 64-bit
    uint64_t value;
};

class CPU {
    uint64_t pc;
    std::array<Register, regNum> regs;
public:
    CPU() = default;
};

} // namespace sim
