`include "core/Decoder.v"

module Executor
(
    input[31:0] _rs1,
    input[31:0] _rs2,
    input[31:0] _imm,
    input _sig_src2,
    input[2:0] _sig_op,

    output reg[31:0] res_,

    input _en_trace,
    input _clk
);

reg[31:0] actual_src2;

always@(*) begin
    case (_sig_src2)
    `DECODER_ALU_SRC2_REG: actual_src2 = _rs2;
    `DECODER_ALU_SRC2_IMM: actual_src2 = _imm;
    endcase
    
    case (_sig_op)
    `DECODER_ALU_OP_ADD: begin
        res_ = _rs1 + actual_src2; 
    end
    `DECODER_ALU_OP_SUB: begin
        res_ = _rs1 - actual_src2; 
    end
    `DECODER_ALU_OP_BEQ: begin
        res_ = (_rs1 == actual_src2) ? 32'1 : 32'0; 
    end
    `DECODER_ALU_OP_BNE: begin
        res_ = (_rs1 != actual_src2) ? 32'1 : 32'0; 
    end
    endcase
end


endmodule