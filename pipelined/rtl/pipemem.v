// The circuit for MEM stage
module pipemem (
    input           clk,
    input   [31:0]  addr,
    input   [31:0]  datain,
    input           we,
    output  [31:0]  dataout
); 
    pl_data_mem dmem(
        .clk(clk),
        .addr(addr),
        .datain(datain),
        .we(we),
        .dataout(dataout)
    );
endmodule