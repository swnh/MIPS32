module vpc (
    input       [31:0]  d,
    input               e,
    input               clk, clrn,
    output  reg [31:0]  q
);
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            q   <= 32'h8000_0000;
        end else if (e) begin 
            q   <= d;
        end
    end
endmodule