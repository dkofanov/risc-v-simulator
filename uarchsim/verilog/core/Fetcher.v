`include "mem/MemUnit.v"
`define DEF_MAX_INSTS 128

module Fetcher
(
    output reg[31:0] pc_,
    output reg[31:0] inst_,
    output reg[31:0] target_branch_,
    output reg[31:0] target_default_,
    output reg is_bcond_,
    output reg is_taken_,
    output reg valid_,
    output reg[31:0] next_pc_,

    input wire _decoder_wb_we,
    input wire _executor_wb_we,
    input wire _memory_wb_we,
    input wire[4:0] _decoder_rd,
    input wire[4:0] _executor_rd,
    input wire[4:0] _memory_rd,
    input wire[31:0] _gpr,
    input wire[31:0] _deopt_target,
    input wire _sig_invalid_prediction,
    input wire _sig_exec_lw_block,

    /* initial */
    input wire _reset,
    input wire[31:0] _init_data[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,

    output reg[31:0] _pc,
    output reg _valid,
    input wire _clk
);

// logger interface:
assign _valid = 1;
assign _pc = next_pc_;

MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS)) inst_mem(._clk(_clk),
                                                    ._reset(_reset),
                                                    ._init_data(_init_data),
                                                    ._we(0),
                                                    ._vptr(_reset ? _init_pc : pc_),
                                                    ._sw_data(0),
                                                    .lw_data_(inst_),
                                                    ._en_trace(0));

wire[6:0] inst_opcode = inst_[6:0];
wire[2:0] inst_funct3 = inst_[14:12];
wire[4:0] rs1 = inst_[19:15];
wire is_jal = (inst_opcode == 7'b1101111);
wire[31:0] imm_jal = {{12{inst_[31]}}, inst_[19:12], inst_[20], inst_[30:21], 1'0};

wire is_jalr = (inst_opcode == 7'b1100111) && (inst_funct3 == 3'b0);
wire[31:0] imm_jalr = {{21{inst_[31]}}, inst_[30:20]};

wire is_bcond = (inst_opcode == 7'b1100011);
wire[31:0] imm_bcond = {{20{inst_[31]}}, inst_[7], inst_[30:25], inst_[11:8], 1'0};

reg[31:0] target_default;
reg[31:0] target_branch;
reg[31:0] target_predicted;
reg[31:0] target_no_invalidation;

reg collision;

reg gpr_match_decode;
reg gpr_match_execute;
reg gpr_match_memory;

always@(*) begin
    is_bcond_ = is_bcond;
    gpr_match_decode = (rs1 == _decoder_rd) && (_decoder_wb_we);
    gpr_match_execute = (rs1 == _executor_rd) && (_executor_wb_we);
    gpr_match_memory = (rs1 == _memory_rd) && (_memory_wb_we);
    
    collision = gpr_match_decode || gpr_match_execute || gpr_match_memory;

    target_branch_ = is_bcond ? pc_ + imm_bcond 
                             : is_jal ? pc_ + imm_jal
                                      : is_jalr ? _gpr : 32'hDEADBEEF; /* NB: jalr may block on fetch */
    target_default_ = pc_ + 4;

    is_taken_ = 0; // always-taken
    target_predicted = is_taken_ ? target_branch_ : target_default_; 

    next_pc_ = (is_jal || is_jalr) ? target_branch_
                                  : is_bcond ? target_predicted
                                             : target_default_;

end

reg clock_skipped;
wire masked_clk = _clk && !_sig_exec_lw_block;

always @(posedge masked_clk) begin
    if (_reset) begin
        pc_ <= _init_pc;
        valid_ <= 1;
    end else if (_sig_invalid_prediction) begin
        pc_ <= _deopt_target;
        valid_ <= 1;
    end else begin
        if (is_jalr) begin
            if (collision) begin
                valid_ <= 0;
            end else begin
                if (!clock_skipped) begin
                    // lock
                    clock_skipped <= 1;
                    valid_ <= 0;
                    pc_ <= pc_;
                end else begin
                    // unlock
                    clock_skipped <= 0;
                    valid_ <= 1;
                    pc_ <= next_pc_;
                end
            end
        end else begin
            pc_ <= next_pc_;
            valid_ <= 1;
        end
    end
end

endmodule
