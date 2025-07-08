module cam8x21 (
    input               clk,
    input               wren,
    input       [19:0]  pattern,
    input       [2:0]   wraddress,
    output      [2:0]   maddress,
    output              mfound
);
    // write cam, update a line with pattern, valid bit <- 1
    reg         [20:0]  ram [0:7];
    always @(posedge clk) begin 
        if (wren) ram[wraddress] <= {1'b1,pattern};
    end

    // fully associative search, should be implemented with CAM cells
    wire        [7:0]   match_line;
    assign match_line[7] = (ram[7] == {1'b1,pattern});
    assign match_line[6] = (ram[6] == {1'b1,pattern});
    assign match_line[5] = (ram[5] == {1'b1,pattern});
    assign match_line[4] = (ram[4] == {1'b1,pattern});
    assign match_line[3] = (ram[3] == {1'b1,pattern});
    assign match_line[2] = (ram[2] == {1'b1,pattern});
    assign match_line[1] = (ram[1] == {1'b1,pattern});
    assign match_line[0] = (ram[0] == {1'b1,pattern});
    assign mfound        = |match_line;

    // encoder for matched address, no multiple-match is allowed
    assign maddress[2] = match_line[7] | match_line[6] | 
                         match_line[5] | match_line[4];
    assign maddress[1] = match_line[7] | match_line[6] |
                         match_line[3] | match_line[2];
    assign maddress[0] = match_line[7] | match_line[5] |
                         match_line[3] | match_line[1];

    // initialize cam, mainly clear valid bit of each line
    integer i;
    initial begin 
        for (i=0; i<8; i=i+1)
            ram[i] = 0;
    end 
endmodule