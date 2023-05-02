function [31:0] LOG2;
   input [31:0] value;
   integer i;
   reg [31:0] j;
   begin
      j = value - 1;
      LOG2 = 0;
      for (i = 0; i < 31; i = i + 1)
        if (j[i]) LOG2 = i+1;
   end
endfunction

`define LOG(COMP, MSG) \
   if (_en_trace) begin $display("[%s] %s", `"COMP`", $sformatf MSG ); end

`define LG(STAGE, MSG) \
begin \
   reg[8*2:1] str_``STAGE = `"STAGE`";\
   $write("\n[%c-state][%d] %h| %s", str_``STAGE[8:1] - 8'd32, STAGE._valid, STAGE._pc, $sformatf MSG ); \
end

`define LG_SUB(STAGE, ELEM) \
begin \
   $write(" %s(%h), ", `"ELEM`", STAGE.ELEM); \
end

`define L( MSG) \
   $display("---------------------| %s", $sformatf MSG );