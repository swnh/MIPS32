// MEM/WB register
module pipememwb (
    input           clk, clrn,
    input   [31:0]  mmo,
    input   [31:0]  malu,
    input   [04:0]  mrn,
    input           mwreg, mm2reg,
    output  [31:0]  wmo,
    output  [31:0]  walu,
    output  [04:0]  wrn,
    output          wwreg, wm2reg
); 
    reg     [31:0]  wmo, walu;
    reg     [04:0]  wrn;
    reg             wwreg, wm2reg;

    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            wwreg   <=  0;          wm2reg  <=  0;
            wmo     <=  0;          walu    <=  0;
            wrn     <=  0;
        end else begin 
            wwreg   <=  mwreg;      wm2reg  <=  mm2reg;
            wmo     <=  mmo;        walu    <=  malu;
            wrn     <=  mrn;
        end
    end
endmodule