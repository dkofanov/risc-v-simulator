`include "mem/TLB.v"

module MemUnit
#(parameter MEM_SLOTS_COUNT=32) (
    input wire _reset,
    input wire[31:0] _init_data[MEM_SLOTS_COUNT - 1:0],

    input wire _we,
    input wire[31:0] _data,
    input wire[31:0] _vptr,

    output wire[31:0] value_,
    
    input wire _en_trace,

    input wire _clk
  );

  wire[LOG2(MEM_SLOTS_COUNT) - 1:0] slot_n;
  TLB#(.MEM_SLOTS_COUNT(MEM_SLOTS_COUNT)) tlb(._reset(_reset), ._vptr(_vptr), .slot_n_(slot_n), ._clk(_clk));

  reg[31:0] memory[MEM_SLOTS_COUNT - 1:0];

  assign value_ = memory[slot_n];

  always @(posedge _clk) begin
    if (_reset) begin
        integer i;
        for (i = 0; i < 200; i++) begin
      memory[i] <= _init_data[i];
        end
    end
    `LOG(MEMUNIT, ("*(%h) == %h (slot %d)", _vptr, value_, tlb.slot_n_));
    if (_we) begin
      memory[tlb.slot_n_] <= _data;
    end 
  end
endmodule