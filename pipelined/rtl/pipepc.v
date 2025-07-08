// PC register
module pipepc (
    input           clk,
    input           clrn,
    input           wpc,                            // pc write enable
    input   [31:0]  npc,                            // next pc
    output  [31:0]  pc
);
    dffe32 prog_cnt (
        .d(npc),
        .clk(clk),
        .clrn(clrn),
        .e(wpc),
        .q(pc)
    );
endmodule