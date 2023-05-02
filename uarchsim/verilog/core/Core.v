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
    input wire _en_trace_reg,
    input wire _en_trace_mem,
    input wire _en_trace_pipeline,
    output wire sig_ebreak_,
    output wire[31:0] PC_,
    output wire[31:0] GPR_[31:0],
    
    input wire _clk
);

    assign GPR_[0] = 'b0;

    /* Bypasses decl: */
    // src
    wire[31:0] bypass_exec;
    wire[31:0] bypass_mem;
    // dst
    wire[31:0] executor_rs1;
    wire[31:0] executor_rs2;
    wire[31:0] memstore_rs2;
    
    wire[31:0] deopt_target;

    wire sig_invalid_prediction;
    wire sig_exec_lw_block;

    Fetcher sf(
        ._gpr(GPR_[sd.rs1_]),

        ._decoder_wb_we(sd._sig_wb_we && sd._valid),
        ._executor_wb_we(se._sig_wb_we && se._valid),
        ._memory_wb_we(sm._sig_wb_we && sm._valid),
        ._decoder_rd(sd.rd_),
        ._executor_rd(se.rd_),
        ._memory_rd(sm.rd_),
        ._sig_invalid_prediction(sig_invalid_prediction),
        ._sig_exec_lw_block(sig_exec_lw_block),
        ._deopt_target(deopt_target),
        ._reset(_reset),
        ._init_data(_init_data),
        ._init_pc(_init_pc),
        ._clk(_clk)
    );
    assign PC_ = sf.pc_;

    Decoder decoder(
        ._inst(sf.inst_)
    );

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
        ._is_bcond(sf.is_bcond_),
        ._is_taken(sf.is_taken_),
        ._target_branch(sf.target_branch_),
        ._target_default(sf.target_default_),
        
        ._valid(!_reset && !sig_invalid_prediction && sf.valid_),
        ._sig_ebreak(decoder.sig_ebreak_),
        ._clk(_clk)
    );

    Executor executor(
        ._rs1(executor_rs1),
        ._rs2(executor_rs2),
        ._imm(sd.imm_),
        ._sig_src2(sd.sig_alu_src2_),
        ._sig_op(sd.sig_alu_op_)
    );
    assign sig_invalid_prediction = sd.is_bcond_ && (sd.is_taken_ != executor.res_[0]);
    assign deopt_target = executor.res_[0] ? sd.target_branch_ : sd.target_default_;

    StageE se(
        ._rd(sd.rd_),
        ._rs2(sd.rs2_),
        ._pc(sd.pc_),
        ._sig_mem_we(sd.sig_mem_we_),
        ._sig_wb_we(sd.sig_wb_we_),
        ._sig_wb_src(sd.sig_wb_src_),
        ._alu_res(executor.res_),
        ._sig_ebreak(sd.sig_ebreak_),

        ._valid(sd.valid_ && !sig_exec_lw_block),
        ._clk(_clk)
    );

    MemUnit#(.MEM_SLOTS_COUNT(`DEF_MAX_INSTS), .IS_STACK(1)) data_mem
    (
        ._vptr(se.alu_res_),
        ._we(se.valid_ ? se.sig_mem_we_ : 0),
        ._sw_data(memstore_rs2),

        ._en_trace(_en_trace_mem),
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

        ._valid(se.valid_),
        ._clk(_clk)
    );

    assign sig_ebreak_ = sm.sig_ebreak_;

    /* Bypasses:*/
    // Exec:
    assign bypass_exec = (se.sig_wb_src_ == `DECODER_WB_SRC_ALU) ? se.alu_res_ : (se.sig_wb_src_ == `DECODER_WB_SRC_PCNEXT) ? (se.pc_ + 4) : 32'hDEADBEEF; 
    assign bypass_mem = (sm.sig_wb_src_ == `DECODER_WB_SRC_ALU) ? sm.alu_res_ : (sm.sig_wb_src_ == `DECODER_WB_SRC_MEM) ? sm.lw_data_ : (sm.pc_ + 4); 

    wire sig_exec_lw_block_rs1 = (sd.rs1_ != 0) && (sd.rs1_ == se.rd_) && (se.sig_wb_we_) && (se.sig_wb_src_ == `DECODER_WB_SRC_MEM) && (se.valid_);
    wire sig_exec_lw_block_rs2 = (sd.rs2_ != 0) && (sd.rs2_ == se.rd_) && (sd.sig_alu_src2_ == `DECODER_ALU_SRC2_REG) && (se.sig_wb_src_ == `DECODER_WB_SRC_MEM) && (se.sig_wb_we_) && (se.valid_);
    wire sig_exec_lw_block = sig_exec_lw_block_rs1 || sig_exec_lw_block_rs2;
    wire sig_rs1_bypass_from_exec = (sd.rs1_ == se.rd_) && (se.sig_wb_we_) && (se.sig_wb_src_ == `DECODER_WB_SRC_ALU) && (se.valid_);
    wire sig_rs2_bypass_from_exec = (sd.rs2_ == se.rd_) && (sd.sig_alu_src2_ == `DECODER_ALU_SRC2_REG) && (se.sig_wb_src_ == `DECODER_WB_SRC_ALU) && (se.sig_wb_we_) && (se.valid_);
    wire sig_rs1_bypass_from_mem = (sd.rs1_ == sm.rd_) && (sm.sig_wb_we_) && (sm.valid_);
    wire sig_rs2_bypass_from_mem = (sd.rs2_ == sm.rd_) && (sd.sig_alu_src2_ == `DECODER_ALU_SRC2_REG) && (sm.sig_wb_we_) && (sm.valid_);
    wire sig_store_bypass = (se.rs2_ == sm.rd_) && (se.sig_mem_we_) && (sm.sig_wb_we_) && (sm.valid_);

    
    assign executor_rs1 = (sd.rs1_ == 5'0) ? 32'0 :
                            sig_rs1_bypass_from_exec ? bypass_exec :
                                sig_rs1_bypass_from_mem ? bypass_mem : GPR_[sd.rs1_];

    assign executor_rs2 = (sd.rs2_ == 5'0) ? 32'0 :
                            sig_rs2_bypass_from_exec ? bypass_exec :
                                sig_rs2_bypass_from_mem ? bypass_mem : GPR_[sd.rs2_];

    assign memstore_rs2 = (se.rs2_ == 5'0) ? 32'0 :
                            sig_store_bypass ? bypass_mem : GPR_[se.rs2_];

    BackWriter back_writer(
        ._we(sm.valid_ ? sm.sig_wb_we_ : 0),
        ._rd(sm.rd_),

        ._res_alu(sm.alu_res_),
        ._res_mem(sm.lw_data_),
        ._res_pc(sm.pc_),
        ._sig_src(sm.sig_wb_src_),

        ._en_trace(_en_trace_reg),
        ._reset(_reset),
        ._clk(!_clk)
    );
    assign GPR_[31:1] = back_writer.gpr_;

    integer i;
    always @(posedge _clk)
    begin
        if (_en_trace_pipeline) begin

        `LG(sf, (""))
            `LG_SUB(sf, inst_)
            `LG_SUB(sf, next_pc_)
            `LG_SUB(sf, target_branch_)
            `LG_SUB(sf, target_default_)
            `LG_SUB(sf, is_bcond_)
            `LG_SUB(sf, is_taken_)
        `LG(sd, (""))
            `LG_SUB(sd, rd_)
            `LG_SUB(sd, rs1_)
            `LG_SUB(sd, rs2_)
            `LG_SUB(sd, sig_mem_we_)
            `LG_SUB(sd, sig_wb_we_)
        `LG(se, (""))
            `LG_SUB(se, alu_res_)
            `LG_SUB(executor, _rs1)
            `LG_SUB(executor, _rs2)
            `LG_SUB(executor, _imm)
        `LG(sm, (""))
            `LG_SUB(sm, rd_)
            `LG_SUB(sm, sig_wb_we_)
            `LG_SUB(sm, sig_wb_src_)
            `LG_SUB(sm, alu_res_)
            `LG_SUB(sm, lw_data_)
            `LG_SUB(sm, pc_)
        $display("");

        end
    end

endmodule
