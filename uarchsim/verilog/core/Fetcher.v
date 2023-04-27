`include "mem/MemUnit.v"
`define DEF_MAX_INSTS 128

module Fetcher
(
    output reg[31:0] pc_,
    output reg[31:0] inst_,
    output reg prediction_is_invalid_,

    input wire _sig_decoder_bcond,
    input wire _sig_executor_bcond_taken,
    input wire _sig_decoder_base_gpr,
    input wire[31:0] _gpr,
    input wire _sig_decoder_is_branch,
    input wire[31:0] _imm,

    input wire _sig_decoder_blocked,
    input wire _en_trace,

    /* initial */
    input wire _reset,
    input wire[31:0] _init_data[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,

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

reg[31:0] target_default;
reg[31:0] target_branch;
reg[31:0] target_predicted;
reg[31:0] target_no_invalidation;
reg[31:0] next_pc;

always@(*) begin
    target_branch = (_sig_decoder_base_gpr ? _gpr : pc_ - 4) + _imm;
    target_default = pc_ + 4;

/*
    Conditional branches handling (5-staged pipeline):
        Branch target pc is may be resolved after D-stage (fetch_clock + 1), 
        condition may be resolved after E-stage (fetch_clock + 2).
*/
    target_predicted = target_branch; // always-taken

    target_no_invalidation = _sig_decoder_is_branch ? _sig_decoder_bcond ? target_predicted 
                                                                         : target_branch
                                                    : target_default;

    prediction_is_invalid_ = cond_should_verify_assumption ?
                                (cond_branch_taken != _sig_executor_bcond_taken) : 0;

    next_pc = prediction_is_invalid_ ? (_sig_executor_bcond_taken ? cond_branch_target : cond_default_target)
                                       : target_no_invalidation;

end

reg cond_should_verify_assumption;
reg cond_branch_taken;
reg[31:0] cond_default_target;
reg[31:0] cond_branch_target;

always @(posedge _clk) begin
    if (!_sig_decoder_blocked) begin
        if (_sig_decoder_bcond) begin
            cond_should_verify_assumption <= 1;
            cond_default_target <= target_default;
            cond_branch_target <= target_branch;
            cond_branch_taken <= 1;  // always-taken
        end else cond_should_verify_assumption <= 0;
        
        if (_reset) pc_ <= _init_pc;
        else pc_ <= next_pc;
    end
    $display("next_pc(%h)", next_pc);
    $display("target_branch(%h)", target_branch);
    $display("target_default(%h)", target_default);
    $display("pc_(%h)", pc_);
    $display("prediction_is_invalid_(%d)", prediction_is_invalid_);
    $display("  cond_should_verify_assumption(%d)", cond_should_verify_assumption);
    $display("  cond_branch_taken(%d)", cond_branch_taken);
    $display("  _sig_executor_bcond_taken(%d)", _sig_executor_bcond_taken);
    $display("_imm(%h)", _imm);
end

endmodule
