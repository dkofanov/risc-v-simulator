module Decoder
(
    input[31:0] _inst,
    output[4:0] rd_,
    output[4:0] rs1_,
    output[4:0] rs2_,

    output sig_rd_,
    output sig_rs1_,
    output sig_rs2_,
    output sig_imm_11_0_,
    output sig_imm_4_0_,
    output sig_imm_11_5_,
    output sig_imm_31_12_,
    output sig_imm_19_12_,
    output sig_imm_11_,
    output sig_imm_4_1_,
    output sig_imm_10_1_,
    output sig_imm_20_
);


assign rd_ = _inst[11:7];
assign rs1_ = _inst[19:15];
assign rs2_ = _inst[24:20];

`define SET_R_SIGNATURE() \
    sig_rd_ = 1; \
    sig_rs1_ = 1; \
    sig_rs2_ = 1; \


`define SET_I_SIGNATURE() \
    sig_rd_ = 1; \
    sig_rs1_ = 1; \
    sig_imm_11_0_ = 1; \


`define SET_S_SIGNATURE() \
    sig_imm_4_0_ = 1; \
    sig_rs1_ = 1; \
    sig_rs2_ = 1; \
    sig_imm_11_5_ = 1; \


`define SET_B_SIGNATURE() \
    sig_imm_11_ = 1; \
    sig_imm_4_1_ = 1; \
    sig_rs1_ = 1; \
    sig_rs2_ = 1; \
    sig_imm_11_5_ = 1; \


`define SET_U_SIGNATURE() \
    sig_rd_ = 1; \
    sig_imm_31_12_ = 1; \


`define SET_J_SIGNATURE() \
    sig_rd_ = 1; \
    sig_imm_19_12_ = 1; \
    sig_imm_11_ = 1; \
    sig_imm_10_1_ = 1; \
    sig_imm_20_ = 1; \

`define SET_A_SIGNATURE() \
    sig_rd_ = 1; \
    sig_rs1_ = 1; \
    sig_rs2_ = 1;

`include "core/generated/decoder_inl.v"


endmodule
