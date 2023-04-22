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
