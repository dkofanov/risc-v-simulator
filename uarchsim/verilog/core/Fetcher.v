`include "mem/MemUnit.v"
`define DEF_MAX_INSTS 128

module Fetcher
(
    /* initial */
    input wire _reset,
    input wire[31:0] _init_data[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,

    /* main */
    output reg[31:0] pc_,
    output reg[31:0] inst_,

    input wire _sig_bcond,
    input wire _bcond_taken,
    input wire _sig_advance_gpr,
    input wire[31:0] _gpr,
    input wire _sig_advance_by_imm,
    input wire[31:0] _imm,
  
    input wire _en_trace,

    input wire _clk
);

MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS)) inst_mem(._clk(_clk),
                                                    ._reset(_reset),
                                                    ._init_data(_init_data),
                                                    ._we(0),
                                                    ._vptr(_reset ? _init_pc : pc_),
                                                    ._sw_data(0),
                                                    .lw_data_(inst_),
                                                    ._en_trace(_en_trace));

reg[31:0] base;
reg[31:0] offs;
always@(*) begin
    base = _sig_advance_gpr? _gpr : pc_;
    if (_sig_bcond) begin
        offs = _bcond_taken ? _imm : 4;
    end else begin 
        offs = _sig_advance_by_imm? _imm : 4;
    end
end

always @(posedge _clk) begin
    pc_ <= _reset ? _init_pc : base + offs;
end

endmodule
