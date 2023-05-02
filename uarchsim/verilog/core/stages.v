module StageD
(
    input wire[4:0] _rd,
    input wire[4:0] _rs1,
    input wire[4:0] _rs2,
    input wire[31:0] _pc,
    input wire[31:0] _imm,
    input wire _sig_mem_we,
    input wire _sig_wb_we,
    input wire[1:0] _sig_wb_src,
    input wire _sig_alu_src2,
    input wire[2:0] _sig_alu_op,
    input wire _sig_ebreak,
    input reg[31:0] _target_branch,
    input reg[31:0] _target_default,
    input reg _is_bcond,
    input reg _is_taken,
    input wire _valid,

    output reg[4:0] rd_,
    output reg[4:0] rs1_,
    output reg[4:0] rs2_,
    output reg[31:0] pc_,
    output reg[31:0] imm_,
    output reg sig_mem_we_,
    output reg sig_wb_we_,
    output reg[1:0] sig_wb_src_,
    output reg sig_alu_src2_,
    output reg[2:0] sig_alu_op_,
    output reg sig_ebreak_,
    output reg[31:0] target_branch_,
    output reg[31:0] target_default_,
    output reg is_bcond_,
    output reg is_taken_,

    input wire _sig_exec_lw_block,
    output reg valid_,
    input wire _clk
);

wire masked_clk = _clk && !_sig_exec_lw_block;
always @(posedge masked_clk) begin
    valid_ <= _valid;
    rd_ <= _rd;
    rs1_ <= _rs1;
    rs2_ <= _rs2;
    imm_ <= _imm;
    pc_ <= _pc;
    sig_mem_we_ <= _sig_mem_we;
    sig_wb_we_ <= _sig_wb_we;
    sig_wb_src_ <= _sig_wb_src;
    sig_alu_src2_ <= _sig_alu_src2;
    sig_alu_op_ <= _sig_alu_op;
    target_branch_ <= _target_branch;
    target_default_ <= _target_default;
    is_bcond_ <= _is_bcond;
    is_taken_ <= _is_taken;
    sig_ebreak_ <= _sig_ebreak;
end
endmodule

module StageE
(
    input wire[4:0] _rd,
    input wire[4:0] _rs2,
    input wire[31:0] _pc,
    input wire _sig_mem_we,
    input wire _sig_wb_we,
    input wire[1:0] _sig_wb_src,
    input wire[31:0] _alu_res,
    input wire _sig_ebreak,
    input wire _valid,

    output reg[4:0] rd_,
    output reg[4:0] rs2_,
    output reg[31:0] pc_,
    output reg sig_mem_we_,
    output reg sig_wb_we_,
    output reg[1:0] sig_wb_src_,
    output reg[31:0] alu_res_,
    output reg sig_ebreak_,
    output reg valid_,
    
    input _clk
);

always @(posedge _clk) begin

    rd_ <= _rd;
    rs2_ <= _rs2;
    alu_res_ <= _alu_res;
    pc_ <= _pc;
    sig_mem_we_ <= _sig_mem_we;
    sig_wb_we_ <= _sig_wb_we;
    sig_wb_src_ <= _sig_wb_src;
    sig_ebreak_ <= _sig_ebreak;
    valid_ <= _valid;
end
endmodule

module StageM
(
    input wire[4:0] _rd,
    input wire _sig_wb_we,
    input wire[1:0] _sig_wb_src,
    input wire[31:0] _pc,
    input wire[31:0] _lw_data,
    input wire[31:0] _alu_res,
    input wire _sig_ebreak,
    input wire _valid,

    output reg[4:0] rd_,
    output reg sig_wb_we_,
    output reg[1:0] sig_wb_src_,
    output reg[31:0] pc_,
    output reg[31:0] lw_data_,
    output reg[31:0] alu_res_,
    output reg sig_ebreak_,
    output reg valid_,
    
    input _clk
);

always @(posedge _clk) begin
    rd_ <= _rd;
    sig_wb_we_ <= _sig_wb_we;
    pc_ <= _pc;
    lw_data_ <= _lw_data;
    alu_res_ <= _alu_res;
    sig_wb_src_ <= _sig_wb_src;
    sig_ebreak_ <= _sig_ebreak;
    valid_ <= _valid;
end

endmodule
