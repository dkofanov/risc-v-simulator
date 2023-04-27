`include "core/Decoder.v" 

module BackWriter
(
    input wire _we,
    input wire[4:0] _rd,

    input wire[31:0] _res_alu,
    input wire[31:0] _res_mem,
    input wire[31:0] _res_pc,
    input wire[1:0] _sig_src,

    output reg[31:0] gpr_[31:1],

    input wire _en_trace,
    input wire _clk
);

reg[31:0] res;

always@(_sig_src) begin
    case(_sig_src)
    `DECODER_WB_SRC_ALU: res = _res_alu;
    `DECODER_WB_SRC_MEM: res = _res_mem;
    `DECODER_WB_SRC_PCNEXT: res = _res_pc + 4;
    endcase
end

always@(posedge _clk) begin
    if (_we) if (_rd != 5'0) begin
        gpr_[_rd] <= res;
        case(_sig_src)
        `DECODER_WB_SRC_ALU: `LOG(W, ("Store alu to reg: x%02d = %h ", _rd, res))
        `DECODER_WB_SRC_MEM: `LOG(W, ("Store mem to reg: x%02d = %h ", _rd, res))
        `DECODER_WB_SRC_PCNEXT: `LOG(W, ("Store pc+4 to reg: x%02d = %h ", _rd, res))
        endcase
    end else begin
        `LOG(W, ("nop"))
    end

end

endmodule