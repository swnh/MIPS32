// The circuit for IF stage
module pipeif (
    input   [31:0]  pc,
    input   [31:0]  bpc,
    input   [31:0]  rpc,                // jr
    input   [31:0]  jpc,                // j/jal
    input   [01:0]  pcsrc,
    output  [31:0]  npc,
    output  [31:0]  pc4,
    output  [31:0]  ins   
);
    // pc + 4
    assign pc4 = pc + 32'h4;

    // next pc 4-to-1 MUX
    reg [31:0] npc;
    always @(*) begin 
        case (pcsrc) 
            2'b00: npc = pc4;
            2'b01: npc = bpc;
            2'b10: npc = rpc;
            2'b11: npc = jpc;
        endcase
    end

    // inst memory
    pl_inst_mem inst_mem (
        .a(pc),
        .inst(ins)
    );
endmodule