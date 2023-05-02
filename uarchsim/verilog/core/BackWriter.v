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
    input wire _reset,
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
    if (_reset) begin
        // set sp:
        gpr_[2] <= 32'hC0000000;
    end else if (_we) begin
        if (_rd != 5'0) begin
            gpr_[_rd] <= res;
        end
        `LOG(W, ("x%02d = %h ", _rd, res))
    end


end

endmodule