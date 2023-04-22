`include "core/Fetcher.v"
`include "core/Decoder.v"

module Core
  (    
    /* initial */
    input wire _reset,
    input wire[31:0] _init_data[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,
    
    /* observe */
    input wire _en_trace,
    input wire _en_trace_fetch,

    input wire _clk
  );

    parameter WORDSZ = 32;

    /* verilator lint_off UNUSED */
    wire[31:0] PC;
    /* verilator lint_off UNUSED */
    reg[31:0] GPR[31:0];
    assign GPR[0] = 'b0;
    
    wire[31:0] fetched_inst;
    Fetcher fetcher(._reset(_reset),
                    ._init_data(_init_data),
                    ._init_pc(_init_pc),
                    .pc_(PC),
                    .inst_(fetched_inst),
                    ._en_trace(_en_trace_fetch),
                    ._clk(_clk));

    wire[4:0] rd;
    wire[4:0] rs1;
    wire[4:0] rs2;

    wire sig_rd_;
    wire sig_rs1_;
    wire sig_rs2_;
    wire sig_imm_11_0_;
    wire sig_imm_4_0_;
    wire sig_imm_11_5_;
    wire sig_imm_31_12_;
    wire sig_imm_19_12_;
    wire sig_imm_11_;
    wire sig_imm_4_1_;
    wire sig_imm_10_1_;
    wire sig_imm_20_;

    wire exec_op;
    wire exec_src1;
    wire exec_src2;
    Decoder decoder(._inst(fetched_inst),
                    .rd_(rd),
                    .rs1_(rs1),
                    .rs2_(rs2),

                    .sig_rd_(sig_rd_),
                    .sig_rs1_(sig_rs1_),
                    .sig_rs2_(sig_rs2_),
                    .sig_imm_11_0_(sig_imm_11_0_),
                    .sig_imm_4_0_(sig_imm_4_0_),
                    .sig_imm_11_5_(sig_imm_11_5_),
                    .sig_imm_31_12_(sig_imm_31_12_),
                    .sig_imm_19_12_(sig_imm_19_12_),
                    .sig_imm_11_(sig_imm_11_),
                    .sig_imm_4_1_(sig_imm_4_1_),
                    .sig_imm_10_1_(sig_imm_10_1_),
                    .sig_imm_20_(sig_imm_20_)
                    );

    Eecuter executor(_ctrl_src1,

            );
        
    

    integer i;
    always @(posedge _clk) begin
        `LOG(CORE, ("INST (%h) %h", fetched_inst, PC));
        `LOG(CORE, ("rd(%d) rs1(%d) rs2(%d)", rd, rs1, rs2));
    end
endmodule
