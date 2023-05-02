`include "common.v"
`include "core/Core.v"

module top
(
    input wire _clk, 

    input wire _reset,
    input wire[31:0] _init_inst_buf[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,

    input wire _en_trace_reg,
    input wire _en_trace_mem,
    input wire _en_trace_pipeline,
    output wire finished_,
    output wire[31:0] PC_,
    output wire[31:0] GPR_[31:0]
);

    /* verilator lint_off UNUSED */
    reg[31:0] start_pc;

    Core core(
            ._reset(_reset),
            ._init_data(_init_inst_buf),
            ._init_pc(_init_pc),
            
            ._en_trace_reg(_en_trace_reg),
            ._en_trace_mem(_en_trace_mem),
            ._en_trace_pipeline(_en_trace_pipeline),
            .sig_ebreak_(finished_),
            .PC_(PC_),
            .GPR_(GPR_),

            ._clk(_clk)
    );

    wire[31:0] data_value;

    always @(posedge _reset) begin
        start_pc <= _init_pc;
    end

endmodule

