module root_newton24 (
    input       [23:0]  d,
    input               fsqrt,
    input               clk, clrn,
    input               ena,
    output  reg [31:0]  q,
    output  reg         busy,
    output              stall,
    output  reg [4:0]   count,
    output  reg [25:0]  reg_x
);
//  reg             q;
    reg     [23:0]  reg_d;
//  reg             reg_x;
//  reg             count;
//  reg             busy;
    wire    [7:0]   x0  = rom(d[23:19]);
    wire    [51:0]  x_2, x2d, x52;
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            count   <= 0;
            busy    <= 0;
            reg_x   <= 0; 
        end else begin 
            if (fsqrt & (count == 0)) begin 
                count   <= 5'b1;
                busy    <= 1'b1;
            end else begin
                if (count == 5'h01) begin 
                    reg_x   <= {2'b1,x0,16'b0};
                    reg_d   <= d;
                end
                if  (count != 0)     count   <= count + 5'b1;
                if  (count == 5'h15) busy    <= 0;
                if  (count == 5'h16) count   <= 0;
                if ((count == 5'h08) ||
                    (count == 5'h0f) ||
                    (count == 5'h16))
                    reg_x   <= x52[50:25];
            end
        end
    end
    assign          stall   = fsqrt & (count == 0) | busy;
    wallace_26x26_product   x2 (reg_x, reg_x, x_2);
    wallace_24x28_product   xd (reg_d, x_2[51:24], x2d);
    wire    [25:0]  b26     = 26'h300_0000 - x2d[49:24];
    wallace_26x26_product   xip1 (reg_x, b26, x52);
    reg     [25:0]  reg_de_x;
    reg     [23:0]  reg_de_d;
    wire    [49:0]  m_s;    // sum:     41 + 8 = 49 bits
    wire    [49:8]  m_c;    // carry:   42 bits
    wallace_24x26           wt (reg_de_d, reg_de_x, m_s[49:8], m_c, m_s[7:0]);  // d * x
    reg     [49:0]  a_s;
    reg     [49:8]  a_c;
    wire    [49:0]  d_x     = {1'b0,a_s} + {a_c,8'b0};
    wire    [31:0]  e2p     = {d_x[47:17],|d_x[16:0]};  // gr,s
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            reg_de_x    <= 0;           reg_de_d    <= 0;
            a_s         <= 0;           a_c         <= 0;
            q           <= 0;
        end else if (ena) begin 
            reg_de_x    <= x52[50:25];  reg_de_d    <= reg_d;
            a_s         <= m_s;         a_c         <= m_c;
            q           <= e2p;
        end
    end
    function  [7:0] rom;                           // a rom table: 1/d^{1/2}
        input [4:0] d;
        case (d)
            5'h08: rom = 8'hff;            5'h09: rom = 8'he1;
            5'h0a: rom = 8'hc7;            5'h0b: rom = 8'hb1;
            5'h0c: rom = 8'h9e;            5'h0d: rom = 8'h9e;
            5'h0e: rom = 8'h7f;            5'h0f: rom = 8'h72;
            5'h10: rom = 8'h66;            5'h11: rom = 8'h5b;
            5'h12: rom = 8'h51;            5'h13: rom = 8'h48;
            5'h14: rom = 8'h3f;            5'h15: rom = 8'h37;
            5'h16: rom = 8'h30;            5'h17: rom = 8'h29;
            5'h18: rom = 8'h23;            5'h19: rom = 8'h1d;
            5'h1a: rom = 8'h17;            5'h1b: rom = 8'h12;
            5'h1c: rom = 8'h0d;            5'h1d: rom = 8'h08;
            5'h1e: rom = 8'h04;            5'h1f: rom = 8'h00;
            default: rom = 8'hff;                  // 0 - 7: not be accessed
        endcase
    endfunction
endmodule