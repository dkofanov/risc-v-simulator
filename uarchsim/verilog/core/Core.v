`include "core/Fetcher.v"
`include "core/Decoder.v"
`include "core/Executor.v"
`include "core/BackWriter.v"

module Core
(    
    /* initial */
    input wire _reset,
    input wire[31:0] _init_data[`DEF_MAX_INSTS - 1:0],
    input wire[31:0] _init_pc,
    
    /* observe */
    input wire _en_trace,
    input wire _en_trace_fetch,
    output wire sig_ebreak_,
    output wire[31:0] PC_,
    output wire[31:0] GPR_[31:0],
    
    input wire _clk
);

    parameter WORDSZ = 32;


    assign GPR_[0] = 'b0;
    
    wire sig_fetch_advance_gpr;
    wire[31:0] fetcher_gpr_target = GPR_[rs1];
    wire sig_fetch_advance_by_imm;
    wire[31:0] fetcher_imm_offset = imm;
    wire sig_fetch_bcond;
    wire[31:0] fetched_inst;
    Fetcher fetcher(._reset(_reset),
                    ._init_data(_init_data),
                    ._init_pc(_init_pc),

                    ._sig_bcond(sig_fetch_bcond),
                    ._bcond_taken(alu_res[0]),
                    ._sig_advance_gpr(sig_fetch_advance_gpr),
                    ._gpr(fetcher_gpr_target),
                    ._sig_advance_by_imm(sig_fetch_advance_by_imm),
                    ._imm(fetcher_imm_offset),

                    .pc_(PC_),
                    .inst_(fetched_inst),
                    ._en_trace(_en_trace_fetch),
                    ._clk(_clk));

    wire[4:0] rd;
    wire[4:0] rs1;
    wire[4:0] rs2;

    wire sig_mem_we;
    wire sig_wb_we;
    wire[1:0] sig_wb_src;

    wire exec_op;
    wire exec_src1;
    wire exec_src2;
    wire[31:0] imm;
    wire[2:0] sig_alu_op;
    wire sig_alu_src2;
    Decoder decoder(._inst(fetched_inst),
                    .rd_(rd),
                    .rs1_(rs1),
                    .rs2_(rs2),

                    .sig_mem_we_(sig_mem_we),
                    .sig_wb_we_(sig_wb_we),
                    .sig_wb_src_(sig_wb_src),
                    .sig_fetch_advance_gpr_(sig_fetch_advance_gpr),
                    .sig_fetch_advance_by_imm_(sig_fetch_advance_by_imm),
                    .sig_fetch_bcond_(sig_fetch_bcond),
                    .sig_alu_src2_(sig_alu_src2),
                    .sig_alu_op_(sig_alu_op),
                    .sig_ebreak_(sig_ebreak_),

                    .imm_(imm),
                    ._clk(_clk)
                    );

    wire[31:0] alu_res;
    Executor executor(
            ._rs1(GPR_[rs1]),
            ._rs2(GPR_[rs2]),
            ._imm(imm),
            ._sig_src2(sig_alu_src2),
            ._sig_op(sig_alu_op),
            .res_(alu_res),
            
            ._en_trace(1),
            ._clk(_clk)
            );

    wire[31:0] sw_data;
    assign sw_data = GPR_[rs2];
    wire[31:0] lw_data;
    MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS), .IS_STACK(1)) data_mem
    (
        ._reset(_reset),
        ._init_data(_init_data),
        ._we(sig_mem_we),
        ._vptr(alu_res),
        ._sw_data(sw_data),
        .lw_data_(lw_data),

        ._en_trace(1),
        ._clk(_clk)
    );

    BackWriter back_writer(
        ._reset(_reset),
        ._we(sig_wb_we),
        ._rd(rd),

        ._res_alu(alu_res),
        ._res_mem(lw_data),
        ._res_pc(PC_),
        ._sig_src(sig_wb_src),

        .gpr_(GPR_[31:1]),
        ._en_trace(1),
        ._clk(_clk)
    );

    integer i;
    always @(posedge _clk) begin
        $display("");
        `LOG(F, ("Fetched: %h (%h)", fetched_inst, PC_));
        `LOG(E, ("OP(%h, %h) = %h", GPR_[rs1], (sig_alu_src2 == `DECODER_ALU_SRC2_REG) ? GPR_[rs2] : imm,  alu_res));
        if (sig_mem_we) begin `LOG(M, ("Store to mem: (*%h) = %h", alu_res, sw_data)); end
        else `LOG(M, ("Addr in mem: (*%h) == %h", alu_res, lw_data));
    end
endmodule
