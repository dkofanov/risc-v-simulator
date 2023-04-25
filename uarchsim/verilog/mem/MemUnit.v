`include "mem/TLB.v"

module MemUnit
#(parameter MEM_SLOTS_COUNT=32, parameter IS_STACK=0) (
    input wire _reset,
    input wire[31:0] _init_data[MEM_SLOTS_COUNT - 1:0],

    input wire _we,
    input wire[31:0] _vptr,
    input wire[31:0] _sw_data,
    output wire[31:0] lw_data_,
    
    input wire _en_trace,

    input wire _clk
  );

  wire[LOG2(MEM_SLOTS_COUNT) - 1:0] slot_n;
  reg[31:0] tlb_vptr;
  always @(*) begin
      if (IS_STACK) begin
          if (_reset) tlb_vptr = _vptr - MEM_SLOTS_COUNT * 4;
          else tlb_vptr = _vptr;
      end else begin
          tlb_vptr = _vptr;
      end
  end

  TLB#(.MEM_SLOTS_COUNT(MEM_SLOTS_COUNT)) tlb(._reset(_reset), ._vptr(tlb_vptr), .slot_n_(slot_n), ._clk(_clk));

  reg[31:0] memory[MEM_SLOTS_COUNT - 1:0];

  assign lw_data_ = memory[slot_n];

  always @(*) begin
    if (_reset) begin
        integer i;
        for (i = 0; i < 200; i++) begin
            memory[i] = _init_data[i];
        end
    end
    if (_we) begin
      memory[tlb.slot_n_] = _sw_data;
    end 
  end

endmodule