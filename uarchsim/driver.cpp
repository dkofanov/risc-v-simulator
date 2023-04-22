#include "Vtop.h"
#include "verilated.h"
#include <array>
#include <iostream>

#include <unistd.h>


constexpr size_t CLOCKS_COUNT_LIMIT = 10;

struct Executable {
    uint32_t start_pc_ = 0x10094;
    std::array<uint32_t, 64> insts_ =  {
        // 00010094 <_start>:
        0xfe010113,  // 10094:  addi    sp,sp,-32
        0x00812e23,  // 10098:  sw      s0,28(sp)
        0x02010413,  // 1009c:  addi    s0,sp,32
        0x000107b7,  // 100a0:  lui     a5,0x10
        0x15078793,  // 100a4:  addi    a5,a5,336 # 10150 <main>
        0xfef42623,  // 100a8:  sw      a5,-20(s0)
        0xfec42783,  // 100ac:  lw      a5,-20(s0)
        0x000780e7,  // 100b0:  jalr    a5
        0x00100073,  // 100b4:  ebreak
        0x00000013,  // 100b8:  nop
        0x00078513,  // 100bc:  mv      a0,a5
        0x01c12403,  // 100c0:  lw      s0,28(sp)
        0x02010113,  // 100c4:  addi    sp,sp,32
        0x00008067,  // 100c8:  ret

        // 000100cc <fibbonaci>:
        0xfe010113,  // 100cc:  addi    sp,sp,-32
        0x00112e23,  // 100d0:  sw      ra,28(sp)
        0x00812c23,  // 100d4:  sw      s0,24(sp)
        0x00912a23,  // 100d8:  sw      s1,20(sp)
        0x02010413,  // 100dc:  addi    s0,sp,32
        0xfea42623,  // 100e0:  sw      a0,-20(s0)
        0xfec42703,  // 100e4:  lw      a4,-20(s0)
        0x00100793,  // 100e8:  li      a5,1
        0x00f71663,  // 100ec:  bne     a4,a5,100f8 <fibbonaci+0x2c>
        0x00100793,  // 100f0:  li      a5,1
        0x0440006f,  // 100f4:  j       10138 <fibbonaci+0x6c>
        0xfec42703,  // 100f8:  lw      a4,-20(s0)
        0x00200793,  // 100fc:  li      a5,2
        0x00f71663,  // 10100:  bne     a4,a5,1010c <fibbonaci+0x40>
        0x00200793,  // 10104:  li      a5,2
        0x0300006f,  // 10108:  j       10138 <fibbonaci+0x6c>
        0xfec42783,  // 1010c:  lw      a5,-20(s0)
        0xfff78793,  // 10110:  addi    a5,a5,-1
        0x00078513,  // 10114:  mv      a0,a5
        0xfb5ff0ef,  // 10118:  jal     ra,100cc <fibbonaci>
        0x00050493,  // 1011c:  mv      s1,a0
        0xfec42783,  // 10120:  lw      a5,-20(s0)
        0xffe78793,  // 10124:  addi    a5,a5,-2
        0x00078513,  // 10128:  mv      a0,a5
        0xfa1ff0ef,  // 1012c:  jal     ra,100cc <fibbonaci>
        0x00050793,  // 10130:  mv      a5,a0
        0x00f487b3,  // 10134:  add     a5,s1,a5
        0x00078513,  // 10138:  mv      a0,a5
        0x01c12083,  // 1013c:  lw      ra,28(sp)
        0x01812403,  // 10140:  lw      s0,24(sp)
        0x01412483,  // 10144:  lw      s1,20(sp)
        0x02010113,  // 10148:  addi    sp,sp,32
        0x00008067,  // 1014c:  ret

        //00010150 <main>:
        0xfe010113,  // 10150:  addi    sp,sp,-32
        0x00112e23,  // 10154:  sw      ra,28(sp)
        0x00812c23,  // 10158:  sw      s0,24(sp)
        0x02010413,  // 1015c:  addi    s0,sp,32
        0xfe042623,  // 10160:  sw      zero,-20(s0)
        0x00b00513,  // 10164:  li      a0,11
        0xf65ff0ef,  // 10168:  jal     ra,100cc <fibbonaci>
        0xfea42623,  // 1016c:  sw      a0,-20(s0)
        0x00000793,  // 10170:  li      a5,0
        0x00078513,  // 10174:  mv      a0,a5
        0x01c12083,  // 10178:  lw      ra,28(sp)
        0x01812403,  // 1017c:  lw      s0,24(sp)
        0x02010113,  // 10180:  addi    sp,sp,32
        0x00008067   // 10184:  ret
    };
};

struct Executable2 {
    uint32_t start_pc_ = 0x10094;
    std::array<uint32_t, 6> insts_ =  {
        // 00010094 <_start>:
        0xfe010113,  // 10094:  addi    sp,sp,-32
        0x00812e23,  // 10098:  sw      s0,28(sp)
        0x02010413,  // 1009c:  addi    s0,sp,32
        0x000107b7,  // 100a0:  lui     a5,0x10
        0x15078793,  // 100a4:  addi    a5,a5,336 # 10150 <main>
        0xfef42623,  // 100a8:  sw      a5,-20(s0)
    };
};

constexpr Executable EXEC;

void LoadProgram(Vtop *top);

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    auto *top = new Vtop;
    top->_en_trace = 1;
    top->_en_trace_fetch = 1;

    LoadProgram(top);
    usleep(1000000);

    while (!Verilated::gotFinish())
    {
        top->_clk ^= 1;
        top->eval();
        usleep(100000);
    }
    delete top;
    return 0;
}

void LoadProgram(Vtop *top)
{
    top->_clk = 0;
    top->_reset = 1;
    top->_init_pc = EXEC.start_pc_;
    for (size_t i = 0; i < EXEC.insts_.size(); i++) {
        top->_init_inst_buf[i] = EXEC.insts_[i];
        printf("set %x<- %x\n",  top->_init_inst_buf[i], EXEC.insts_[i]);
    }
    top->eval();

    top->_clk ^= 1;
    top->eval();

    top->_clk ^= 1;
    top->_reset = 0;
    top->eval();

    top->_clk ^= 1;
    top->eval();
}
