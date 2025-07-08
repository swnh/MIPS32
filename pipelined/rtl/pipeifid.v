// IF/ID pipeline register
module pipeifid (
    input           clk,
    input           wir,
    input           clrn,
    input   [31:0]  pc4,
    input   [31:0]  ins,
    output  [31:0]  dpc4,           // pc4 in ID
    output  [31:0]  dinst
);
    dffe32 pc_plus4 (
        .d(pc4),
        .clk(clk),
        .clrn(clrn),
        .e(wir),
        .q(dpc4)
    );
    dffe32 instruction (
        .d(ins),
        .clk(clk),
        .clrn(clrn),
        .e(wir),
        .q(dinst)
    );
endmodule