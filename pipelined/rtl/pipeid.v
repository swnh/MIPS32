// The circuit for ID stage
module pipeid (
    input           clk,
    input           clrn,
    input   [31:0]  dpc4,                            // pc+4 in ID
    input   [31:0]  dinst,                           // inst in ID
    input   [31:0]  wdi,                             // data in WB
    input   [31:0]  ealu,                            // alu res in EXE
    input   [31:0]  malu,                            // alu res in MEM
    input   [31:0]  mmo,                             // mem out in MEM
    input   [04:0]  ern,                             // dest reg # in EXE
    input   [04:0]  mrn,                             // dest reg # in MEM
    input   [04:0]  wrn,                             // dest reg # in WB
    input           ewreg,
    input           em2reg,
    input           mwreg,
    input           mm2reg,
    input           wwreg,
    output  [31:0]  bpc,
    output  [31:0]  jpc,
    output  [31:0]  a, b,
    output  [31:0]  dimm,
    output  [04:0]  rn,
    output  [03:0]  aluc,
    output  [01:0]  pcsrc,
    output          nostall,
    output          wreg,
    output          m2reg,
    output          wmem,
    output          aluimm,
    output          shift,
    output          jal
);
    wire    [05:0]  op   = dinst[31:26];
    wire    [04:0]  rs   = dinst[25:21];
    wire    [04:0]  rt   = dinst[20:16];
    wire    [04:0]  rd   = dinst[15:11];
    wire    [05:0]  func = dinst[05:00];
    wire    [15:0]  imm  = dinst[15:00];
    wire    [25:0]  addr = dinst[25:00];
    wire            regrt;
    wire            sext;
    wire    [31:0]  qa, qb;
    wire    [01:0]  fwda, fwdb;
    wire    [15:0]  s16   = {16{sext & dinst[15]}};
    wire    [31:0]  offset = {dimm[29:0], 2'b00};     // branch offset
    wire            rsrtequ = ~|(a^b);

    pipeidcu cu (
        .op(op),
        .func(func),
        .rs(rs),
        .rt(rt),
        .ern(ern),
        .mrn(mrn),
        .ewreg(ewreg),
        .em2reg(em2reg),
        .mwreg(mwreg),
        .mm2reg(mm2reg),
        .rsrtequ(rsrtequ),
        .aluc(aluc),
        .pcsrc(pcsrc),
        .fwda(fwda),
        .fwdb(fwdb),
        .wreg(wreg),
        .m2reg(m2reg),
        .wmem(wmem),
        .aluimm(aluimm),
        .shift(shift),
        .jal(jal),
        .regrt(regrt),
        .sext(sext),
        .nostall(nostall)
    );

    regfile rf (
        .rna(rs),
        .rnb(rt),
        .d(wdi),
        .wn(wrn),
        .we(wwreg),
        .clk(~clk), // falling-edge
        .clrn(clrn),
        .qa(qa),
        .qb(qb)
    );

    reg [31:0] a, b;
    always @(*) begin 
        case (fwda)
            2'b00: a = qa;
            2'b01: a = ealu;
            2'b10: a = malu;
            2'b11: a = mmo;
        endcase
        
        case (fwdb)
            2'b00: b = qb;
            2'b01: b = ealu;
            2'b10: b = malu;
            2'b11: b = mmo;
        endcase
    end
    
    assign rn = regrt ? rt : rd;
    assign bpc  = dpc4 + offset;
    assign dimm = {s16,imm};
    assign jpc  = {dpc4[31:28],addr,2'b00};
endmodule