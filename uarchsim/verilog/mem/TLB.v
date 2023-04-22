
/**
 * Translation: 
 *   def pptr <=> slot_n
 *   pptr = vptr - init_vptr
 */
module TLB

#(parameter MEM_SLOTS_COUNT=32) (
    /* initial */
    input wire _reset,

    input wire[31:0] _vptr,
    output wire[LOG2(MEM_SLOTS_COUNT) - 1:0] slot_n_,

    /* for sync reset only */
    input wire _clk
);

integer WORDSZ_BYTES = 4;

reg[31:0] init_vptr;

/* Translation */
/* verilator lint_off UNUSED */
wire[31:0] offs = _vptr - init_vptr >> LOG2(WORDSZ_BYTES);
assign slot_n_ = offs[LOG2(MEM_SLOTS_COUNT) - 1:0];

always @(posedge _clk) begin
    if (_reset) begin
        init_vptr <= _vptr;
    end
end


endmodule