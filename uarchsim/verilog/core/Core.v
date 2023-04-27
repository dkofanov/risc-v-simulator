`include "core/Fetcher.v"
`include "core/Decoder.v"
`include "core/Executor.v"
`include "core/BackWriter.v"
`include "core/stages.v"

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

    assign GPR_[0] = 'b0;

    /* Bypasses decl: */
    // src
    wire[31:0] fetch_bypass_exec;
    wire[31:0] fetch_bypass_mem;
    wire[31:0] exec_bypass_exec;
    wire[31:0] exec_bypass_mem;
    // dst
    wire[31:0] fetcher_gpr;
    wire[31:0] executor_rs1;
    wire[31:0] executor_rs2;
    wire[31:0] memory_sw_data;

    wire sig_jalr_after_lw;
    wire sig_alu_after_lw;
    
    wire sig_fetcher_base_gpr;
    wire sig_fetcher_is_branch;
    wire sig_fetcher_cond_branch;
    wire sig_fetcher_branch_taken;
    wire sig_decoder_blocked;
    wire[31:0] fetcher_imm;

    Fetcher fetcher(
        ._sig_decoder_base_gpr(sig_fetcher_base_gpr),
        ._sig_decoder_is_branch(sig_fetcher_is_branch),
        ._sig_decoder_bcond(sig_fetcher_cond_branch),
        ._sig_executor_bcond_taken(sig_fetcher_branch_taken),
        ._gpr(fetcher_gpr),
        ._imm(fetcher_imm),
        ._sig_decoder_blocked(sig_decoder_blocked),
        ._reset(_reset),
        ._init_data(_init_data),
        ._init_pc(_init_pc),
        ._en_trace(_en_trace_fetch),
        ._clk(_clk)
    );
    assign PC_ = fetcher.pc_;

    StageF sf(
        ._inst(fetcher.inst_),
        ._pc(fetcher.pc_),
        
        ._sig_lw_blocked(sig_jalr_after_lw || sig_alu_after_lw || sig_decoder_blocked),
        ._valid(!_reset && !fetcher.prediction_is_invalid_),
        ._clk(_clk)
    );

    Decoder decoder(
        ._inst(sf.inst_)
    );

    assign sig_fetcher_base_gpr = decoder.sig_fetch_base_gpr_;
    assign sig_fetcher_is_branch = decoder.sig_fetch_is_branch_;
    assign sig_fetcher_cond_branch = decoder.sig_fetch_bcond_;
    assign fetcher_imm = decoder.imm_;
    wire sig_jalr_after_lw;

    StageD sd(
        ._rd(decoder.rd_),
        ._rs1(decoder.rs1_),
        ._rs2(decoder.rs2_),
        ._pc(sf.pc_),
        ._imm(decoder.imm_),
        ._sig_mem_we(decoder.sig_mem_we_),
        ._sig_wb_we(decoder.sig_wb_we_),
        ._sig_wb_src(decoder.sig_wb_src_),
        ._sig_alu_src2(decoder.sig_alu_src2_),
        ._sig_alu_op(decoder.sig_alu_op_),
        ._sig_ebreak(decoder.sig_ebreak_),
        
        ._sig_is_branch(sig_fetcher_is_branch),
        ._sig_lw_fetch_blocked(sig_jalr_after_lw),
        ._sig_lw_alu_blocked(sig_alu_after_lw),
        ._valid(!_reset && !fetcher.prediction_is_invalid_),
        ._clk(_clk)
    );
    assign sig_decoder_blocked = sd.was_blocked_alu_;

    Executor executor(
        ._rs1(executor_rs1),
        ._rs2(executor_rs2),
        ._imm(sd.imm_),
        ._sig_src2(sd.sig_alu_src2_),
        ._sig_op(sd.sig_alu_op_)
    );
    assign sig_fetcher_branch_taken = executor.res_[0]; 

    StageE se(
        ._rd(sd.rd_),
        ._rs2(sd.rs2_),
        ._pc(sd.pc_),
        ._sig_mem_we(sd.sig_mem_we_),
        ._sig_wb_we(sd.sig_wb_we_),
        ._sig_wb_src(sd.sig_wb_src_),
        ._alu_res(executor.res_),
        ._sig_ebreak(sd.sig_ebreak_),

        ._sig_sd_blocked(sd.was_blocked_ != 0),
        ._valid(sd.valid_ ),
        ._clk(_clk)
    );

    MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS), .IS_STACK(1)) data_mem
    (
        ._vptr(se.alu_res_),
        ._we(se.valid_ ? se.sig_mem_we_ : 0),
        ._sw_data(GPR_[se.rs2_]),

        ._reset(_reset),
        ._init_data(_init_data),
        ._clk(!_clk)
    );

    StageM sm
    (
        ._rd(se.rd_),
        ._pc(se.pc_),
        ._sig_wb_we(se.sig_wb_we_),
        ._sig_wb_src(se.sig_wb_src_),
        ._alu_res(se.alu_res_),
        ._lw_data(data_mem.lw_data_),
        ._sig_ebreak(se.sig_ebreak_),

        ._valid(se.valid_ && !sig_alu_after_lw),
        ._clk(_clk)
    );

    assign sig_ebreak_ = sm.sig_ebreak_;

    /* Bypasses: */
    // Fetch:
    assign fetch_bypass_exec = se._alu_res;
    assign fetch_bypass_mem = (sm._sig_wb_src == `DECODER_WB_SRC_ALU) ? sm._alu_res : sm._lw_data /* jal-after-jalr (`DECODER_WB_SRC_PCNEXT) is not supported */;

    assign sig_jalr_after_lw = decoder.sig_fetch_is_branch_ &&
                             decoder.sig_fetch_base_gpr_ &&
                             sig_fetch_bypass_from_exec &&
                             (se._sig_wb_src == `DECODER_WB_SRC_MEM);

    wire sig_fetch_bypass_from_exec = (sd._rs1 != 0) && (sd._rs1 == se._rd) && (se._sig_wb_we) && (se._valid);
    wire sig_fetch_bypass_from_mem = (sd._rs1 != 0) && (sd._rs1 == sm._rd) && (sm._sig_wb_we) && (sm._valid);

    assign fetcher_gpr = (sd._rs1 == 5'0) ? 32'0 :
                            sig_fetch_bypass_from_exec ? fetch_bypass_exec :
                                sig_fetch_bypass_from_mem ? fetch_bypass_mem : GPR_[sd._rs1];

    // Exec:
    assign exec_bypass_exec = se.alu_res_;
    assign exec_bypass_mem = (sm.sig_wb_src_ == `DECODER_WB_SRC_ALU) ? sm.alu_res_ : sm.lw_data_ /* jal-after-jalr (`DECODER_WB_SRC_PCNEXT) is not supported */;

    wire sig_exec_rs1_bypass_from_exec = (sd.rs1_ != 0) && (sd.rs1_ == se.rd_) && (se.sig_wb_we_) && (se.valid_);
    wire sig_exec_rs1_bypass_from_mem = (sd.rs1_ != 0) && (sd.rs1_ == sm.rd_) && (sm.sig_wb_we_) && (sm.valid_);
    wire sig_exec_rs2_bypass_from_exec = (sd.rs2_ != 0) && (sd.rs2_ == se.rd_) && (sd.sig_alu_src2_ == `DECODER_ALU_SRC2_REG) && (se.sig_wb_we_) && (se.valid_);
    wire sig_exec_rs2_bypass_from_mem = (sd.rs2_ != 0) && (sd.rs2_ == sm.rd_) && (sd.sig_alu_src2_ == `DECODER_ALU_SRC2_REG) && (sm.sig_wb_we_) && (sm.valid_);

    assign sig_alu_after_lw = (sig_exec_rs1_bypass_from_exec || sig_exec_rs2_bypass_from_exec) && (se.sig_wb_src_ == `DECODER_WB_SRC_MEM);
    
    assign executor_rs1 = (sd.rs1_ == 5'0) ? 32'0 :
                            sig_exec_rs1_bypass_from_exec ? exec_bypass_exec :
                                sig_exec_rs1_bypass_from_mem ? exec_bypass_mem : GPR_[sd.rs1_];

    assign executor_rs2 = (sd.rs2_ == 5'0) ? 32'0 :
                            sig_exec_rs2_bypass_from_exec ? exec_bypass_exec :
                                sig_exec_rs2_bypass_from_mem ? exec_bypass_mem : GPR_[sd.rs2_];


    BackWriter back_writer(
        ._we(sm.valid_ ? sm.sig_wb_we_ : 0),
        ._rd(sm.rd_),

        ._res_alu(sm.alu_res_),
        ._res_mem(sm.lw_data_),
        ._res_pc(sm.pc_),
        ._sig_src(sm.sig_wb_src_),

        ._clk(!_clk)
    );
    assign GPR_[31:1] = back_writer.gpr_;

    integer i;
    always @(posedge _clk) begin
        `LG(sf, ("%h| inst(%h), base_gpr(%d), offset(%h), (eb[%h] = %d, mb[%h] = %d)", sf.pc_, sf.inst_, sig_fetcher_base_gpr, fetcher_imm, fetch_bypass_exec, sig_fetch_bypass_from_exec, fetch_bypass_mem, sig_fetch_bypass_from_mem));
        `LG(sd, ("%h| branch(%d), f_blocked(%d), alu_blocked(%d), was_blocked(%d)", sd.pc_, sig_fetcher_is_branch, sd._sig_lw_fetch_blocked, sd._sig_lw_alu_blocked, sd.was_blocked_));
        `LG(se, ("%h| alu_res: %h", se.pc_, se.alu_res_));
        `LG(sm, ("%h| vptr(%h), alu_data(%h), lw_data(%h)", sm.pc_, data_mem._vptr, sm.alu_res_, sm.lw_data_));
        //`L(sw, ("%h| rd(x%02d), is_store(%d), src_t(%d), alu(%h), mem(%h), pc(%h)", sm.pc_, sm.rd_, sm.sig_wb_we_, sm.sig_wb_src_, back_writer._res_alu, back_writer._res_mem, back_writer._res_pc));
        $display("decoder_ebreak(%d)", decoder.sig_ebreak_);
        $display("sd._ebreak(%d)", sd._sig_ebreak);
        $display("sd.ebreak_(%d)", sd.sig_ebreak_);
        $display("se._ebreak(%d)", se._sig_ebreak);
        $display("se.ebreak_(%d)", se.sig_ebreak_);
        $display("sm._ebreak(%d)", sm._sig_ebreak);
        $display("sm.ebreak_(%d)", sm.sig_ebreak_);
        $display("");
    end
endmodule
