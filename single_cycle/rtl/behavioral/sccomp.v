module sccomp (clk, clrn, inst, pc, aluout, memout);    // single cycle computer
    input           clk, clrn;                          // clock and reset
    output  [31:0]  pc;                                 // program counter
    output  [31:0]  inst;                               // instruction
    output  [31:0]  aluout;                             // alu output
    output  [31:0]  memout;                             // data memory output
    wire    [31:0]  data;                               // data to data memory
    wire            wmem;                               // write data memory

    // cpu
    sccpu cpu (                                         
        .clk(clk),
        .clrn(clrn),
        .inst(inst),
        .mem(memout),
        .pc(pc),
        .wmem(wmem),
        .alu(aluout),
        .data(data)
    );

    // inst memory
    scinstmem imem (
        .a(pc),
        .inst(inst)
    );

    // data memory
    scdatamem dmem (
        .clk(clk),
        .dataout(memout),
        .datain(data),
        .addr(aluout),
        .we(wmem)
    );
endmodule