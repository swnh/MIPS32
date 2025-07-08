// The circuit for WB stage
module pipewb (
    input   [31:0]  walu,
    input   [31:0]  wmo,
    input           wm2reg,
    output  [31:0]  wdi
); 
    assign wdi = wm2reg ? wmo : walu;
endmodule