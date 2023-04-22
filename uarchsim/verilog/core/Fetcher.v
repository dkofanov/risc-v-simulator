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
  
    input wire _en_trace,

    input wire _clk
);

MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS)) inst_mem(._clk(_clk),
                                                    ._reset(_reset),
                                                    ._init_data(_init_data),
                                                    ._we(0),
                                                    ._data(0),
                                                    ._vptr(_reset ? _init_pc : pc_),
                                                    .value_(inst_),
                                                    ._en_trace(_en_trace));

always @(posedge _clk) begin
    `LOG(FETCHER, ("New pc: %h (_reset == %d)", _reset ? _init_pc : pc_ + 4, _reset));
    pc_ <= _reset ? _init_pc : pc_ + 4;
    `LOG(FETCHER, ("Fetched: %h", inst_));
end

endmodule
