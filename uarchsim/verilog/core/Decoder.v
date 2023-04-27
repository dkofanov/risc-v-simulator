`ifndef CORE_DECODER_v
`define CORE_DECODER_v

`define DECODER_ALU_SRC2_REG 0
`define DECODER_ALU_SRC2_IMM 1
`define DECODER_ALU_OP_ADD 0
`define DECODER_ALU_OP_SUB 1
`define DECODER_ALU_OP_MUL 2
`define DECODER_ALU_OP_DIV 3
`define DECODER_ALU_OP_BNE 4
`define DECODER_ALU_OP_BEQ 5
`define DECODER_ALU_OP_BLT 6
`define DECODER_ALU_OP_BGT 7

`define DECODER_WB_SRC_ALU 0
`define DECODER_WB_SRC_MEM 1
`define DECODER_WB_SRC_PCNEXT 2

module Decoder
(
    input[31:0] _inst,

    output reg[4:0] rd_,
    output reg[4:0] rs1_,
    output reg[4:0] rs2_,
    output reg[31:0] imm_,

    output reg[1:0] sig_wb_src_,
    output wire sig_fetch_base_gpr_,
    output wire sig_fetch_is_branch_,
    output wire sig_fetch_bcond_,
    output wire sig_ebreak_,

    output reg sig_alu_src2_,
    output reg[2:0] sig_alu_op_,

    output reg sig_mem_we_,
    output reg sig_wb_we_
);

`define SET_R_SIGNATURE() \
    sig_alu_src2_ = `DECODER_ALU_SRC2_REG; \
    sig_wb_we_ = 1; \
    sig_wb_src_ = `DECODER_WB_SRC_ALU;


`define SET_I_SIGNATURE() \
    imm_ = 32'0; \
    imm_[10:0] = _inst[30:20]; \
    imm_[31:11] = {21{_inst[31]}}; \
    sig_wb_we_ = 1; \
    sig_alu_src2_ = `DECODER_ALU_SRC2_IMM; \
    sig_wb_src_ = `DECODER_WB_SRC_ALU;

`define SET_S_SIGNATURE() \
    imm_ = 32'0; \
    imm_[4:0] = _inst[11:7]; \
    imm_[10:5] = _inst[30:25]; \
    imm_[31:11] = {21{_inst[31]}}; \
    sig_mem_we_ = 1; \
    sig_alu_src2_ = `DECODER_ALU_SRC2_IMM; \
    sig_alu_op_ = `DECODER_ALU_OP_ADD;

`define SET_B_SIGNATURE() \
    imm_ = 32'0; \
    imm_[4:1] = _inst[11:8]; \
    imm_[10:5] = _inst[30:25]; \
    imm_[11] = _inst[7]; \
    imm_[31:12] = {20{_inst[31]}}; \
    sig_fetch_is_branch_ = 1; \
    sig_fetch_bcond_ = 1; \
    sig_alu_src2_ = `DECODER_ALU_SRC2_REG; \
    sig_alu_op_ = `DECODER_ALU_OP_BNE;

`define SET_U_SIGNATURE() \
    imm_ = 32'0; \
    imm_[11:0] = 12'0; \
    imm_[31:12] = _inst[31:12]; \
    rs1_ = 5'0; \
    sig_wb_we_ = 1; \
    sig_alu_src2_ = `DECODER_ALU_SRC2_IMM; \
    sig_wb_src_ = `DECODER_WB_SRC_ALU;

`define SET_J_SIGNATURE() \
    imm_ = 32'0; \
    imm_[10:1] = _inst[30:21]; \
    imm_[11] = _inst[20]; \
    imm_[19:12] = _inst[19:12]; \
    imm_[31:20] = {12{_inst[31]}}; \
    sig_wb_we_ = 1; \
    sig_wb_src_ = `DECODER_WB_SRC_PCNEXT; \
    sig_fetch_is_branch_ = 1;

`define SET_A_SIGNATURE() 

wire[6:0] opcode = _inst[6:0];
wire[2:0] funct3 = _inst[14:12];
wire[4:0] funct5 = _inst[31:27];
wire[6:0] funct7 = _inst[31:25];
wire[11:0] imm_11_0 = _inst[31:20];
integer label;

always@(*) begin
    rd_ = _inst[11:7];
    rs1_ = _inst[19:15];
    rs2_ = _inst[24:20];
    sig_mem_we_ = 0;
    sig_wb_we_ = 0;
    sig_wb_src_ = `DECODER_WB_SRC_ALU;
    sig_fetch_base_gpr_ = 0;
    sig_fetch_is_branch_ = 0;
    sig_fetch_bcond_ = 0;
    sig_ebreak_ = 0;
    sig_alu_op_ = `DECODER_ALU_OP_ADD;
    sig_alu_src2_ = `DECODER_ALU_SRC2_REG;

`include "core/generated/decoder_inl.v"

    case(label)
    `ADDI: sig_alu_op_ = `DECODER_ALU_OP_ADD;

    `LW: begin
        sig_alu_op_ = `DECODER_ALU_OP_ADD;
        sig_wb_src_ = `DECODER_WB_SRC_MEM;
    end
    
    `JALR: begin
        sig_wb_src_ = `DECODER_WB_SRC_PCNEXT;
        sig_fetch_is_branch_ = 1;
        sig_fetch_base_gpr_ = 1;
    end

    `BEQ: sig_alu_op_ = `DECODER_ALU_OP_BEQ;

    `EBREAK: sig_ebreak_ = 1;

    endcase
end

endmodule

`endif
