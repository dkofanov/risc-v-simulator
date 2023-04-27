module StageF
(
    input wire[31:0] _pc,
    input wire[31:0] _inst,
    input wire _valid,

    output reg[31:0] pc_,
    output reg[31:0] inst_,

    input _sig_lw_blocked,
    output wire valid_,
    input wire _clk
);

wire _en_trace = 1;

always @(posedge _clk) begin
    if (!_sig_lw_blocked) begin
        pc_ <= _pc;
        inst_ <= _inst;
        valid_ <= _valid;
    end
end
endmodule

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
    output reg valid_,

    output reg[1:0] was_blocked_,
    output reg was_blocked_alu_,
    input _sig_is_branch,
    input _sig_lw_fetch_blocked,
    input _sig_lw_alu_blocked,
    input _clk
);


always @(posedge _clk) begin
    if (!_sig_lw_fetch_blocked && !_sig_lw_alu_blocked) begin
        if ((was_blocked_ == 0) && !was_blocked_alu_) begin
            if (_sig_is_branch) begin
                was_blocked_ <= 1;
            end
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
                sig_ebreak_ <= _sig_ebreak;
        end else begin
            if (was_blocked_ != 0) begin
                was_blocked_ <= was_blocked_ - 1;
            end
            else if (was_blocked_alu_ != 0) begin
                was_blocked_alu_ <= was_blocked_alu_ - 1;
            end
        end
    end else if (_sig_lw_fetch_blocked) begin
        was_blocked_ <= 2;
        valid_ <= 0;
    end else if (_sig_lw_alu_blocked) begin
        was_blocked_alu_ <= 1;
        valid_ <= 0;
    end 
end
endmodule

module StageE
(
    input wire[4:0] _rd,
    input wire[4:0] _rs2,
    input wire[31:0] _pc,
    input wire[31:0] _imm,
    input wire _sig_mem_we,
    input wire _sig_wb_we,
    input wire[1:0] _sig_wb_src,
    input wire[31:0] _alu_res,
    input wire _sig_ebreak,
    input wire _valid,

    output reg[4:0] rd_,
    output reg[4:0] rs2_,
    output reg[31:0] pc_,
    output reg[31:0] imm_,
    output reg sig_mem_we_,
    output reg sig_wb_we_,
    output reg[1:0] sig_wb_src_,
    output reg[31:0] alu_res_,
    output reg sig_ebreak_,
    output reg valid_,
    
    input _sig_sd_blocked,
    input _clk
);

always @(posedge _clk) begin

    rd_ <= _rd;
    rs2_ <= _rs2;
    alu_res_ <= _alu_res;
    pc_ <= _pc;
    imm_ <= _imm;
    sig_mem_we_ <= _sig_mem_we;
    sig_wb_we_ <= _sig_wb_we;
    sig_wb_src_ <= _sig_wb_src;
    sig_ebreak_ <= _sig_ebreak;
    valid_ <= !_sig_sd_blocked && _valid;
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
    input wire[31:0] _imm,
    input wire _sig_ebreak,
    input wire _valid,

    output reg[4:0] rd_,
    output reg sig_wb_we_,
    output reg[1:0] sig_wb_src_,
    output reg[31:0] pc_,
    output reg[31:0] lw_data_,
    output reg[31:0] alu_res_,
    output reg[31:0] imm_,
    output reg sig_ebreak_,
    output reg valid_,
    
    input _clk
);

wire _en_trace = 1;

always @(posedge _clk) begin
    rd_ <= _rd;
    sig_wb_we_ <= _sig_wb_we;
    pc_ <= _pc;
    lw_data_ <= _lw_data;
    alu_res_ <= _alu_res;
    imm_ <= _imm;
    sig_wb_src_ <= _sig_wb_src;
    sig_ebreak_ <= _sig_ebreak;
    valid_ <= _valid;
end

endmodule
