// ID/EXE register
module pipeidexe (
    input           clk,
    input           clrn,
    input   [31:0]  da,
    input   [31:0]  db,
    input   [31:0]  dimm,
    input   [31:0]  dpc4,
    input   [04:0]  drn,
    input   [03:0]  daluc,
    input           dwreg, dm2reg, dwmem, daluimm, dshift, djal,
    output  [31:0]  ea,
    output  [31:0]  eb,
    output  [31:0]  eimm,
    output  [31:0]  epc4,
    output  [04:0]  ern,
    output  [03:0]  ealuc,
    output          ewreg, em2reg, ewmem, ealuimm, eshift, ejal
); 

    reg     [31:0]  ea, eb, eimm, epc4;
    reg     [04:0]  ern;
    reg     [03:0]  ealuc;
    reg             ewreg, em2reg, ewmem, ealuimm, eshift, ejal;

    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            ewreg   <=  0;          em2reg  <=  0;
            ewmem   <=  0;          ealuc   <=  0;
            ealuimm <=  0;          ea      <=  0;
            eb      <=  0;          eimm    <=  0;
            ern     <=  0;          eshift  <=  0;
            ejal    <=  0;          epc4    <=  0;
        end else begin 
            ewreg   <=  dwreg;      em2reg  <=  dm2reg;
            ewmem   <=  dwmem;      ealuc   <=  daluc;
            ealuimm <=  daluimm;    ea      <=  da;
            eb      <=  db;         eimm    <=  dimm;
            ern     <=  drn;        eshift  <=  dshift;
            ejal    <=  djal;       epc4    <=  dpc4;
        end
    end
endmodule