module ram8x24 (
    input       [2:0]   address,
    input       [23:0]  data,
    input               clk,
    input               we,
    output      [23:0]  q
);
    reg         [23:0]  ram [0:7];
    always @(posedge clk) begin 
        if (we) ram[address] <= data;
    end
    assign q = ram[address];

    integer i;
    initial begin 
        for (i=0 ; i<8; i=i+1)
            ram[i] = 24'h0;
    end
endmodule