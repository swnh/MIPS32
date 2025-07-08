/************************************************
  The Verilog HDL code example is from the book
  Computer Principles and Design in Verilog HDL
  by Yamin Li, published by A JOHN WILEY & SONS
************************************************/
`timescale 1ns/1ns
module fpu_1_iu_tb;
    reg         clk,memclk,clrn;
    wire [31:0] pc,inst,ealu,malu,walu;
    wire [31:0] e3d,wd;
    wire [4:0]  e1n,e2n,e3n,wn;
    wire        ww,stl_lw,stl_fp,stl_lwc1,stl_swc1,stl;
    wire        e;
    wire [4:0]  cnt_div,cnt_sqrt;
    fpu_1_iu cpu (
      .clk(clk),            .memclk(memclk),      .clrn(clrn),
      .pc(pc),              .inst(inst),
      .ealu(ealu),          .malu(malu),          .walu(walu),
      .e1n(e1n),            .e2n(e2n),            .e3n(e3n),
      .wn(wn),              .wd(wd),              .ww(ww),
      .e3d(e3d),            .cnt_div(cnt_div),    .cnt_sqrt(cnt_sqrt),
      .e(e),                .stl_lw(stl_lw),      .stl_fp(stl_fp),      
      .stl_lwc1(stl_lwc1),  .stl_swc1(stl_swc1),  .stl(stl)
    );
    initial begin
           clrn   = 0;
           memclk = 0;
           clk    = 1;
        #1 clrn   = 1;
    end
    always #1 memclk = !memclk;
    always #2 clk  = !clk;
endmodule
/*
  24 -  52.001 ns
  48 -  76.001 ns
 128 - 412.000 ns
*/
