module newton24 (
    input           [23:0]  a,
    input           [23:0]  b,
    input                   fdiv,
    input                   clk, clrn,
    input                   ena,
    output          [31:0]  q,
    output  reg             busy,
    output          [4:0]   count,
    output          [25:0]  reg_x,
    output                  stall
);
    reg             [31:0]  q;
    reg             [25:0]  reg_x;
    reg             [23:0]  reg_a;
    reg             [23:0]  reg_b;
    reg             [4:0]   count;
    wire            [49:0]  bxi;
    wire            [51:0]  x52;
    wire            [49:0]  d_x;
    wire            [31:0]  e2p;
    wire            [7:0]   x0      = rom(b[22:9]);
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            busy    <= 0;
            count   <= 0;
            reg_x   <= 0;
        end else begin
            if (fdiv & (count == 0)) begin
                count   <= 5'b1;
                busy    <= 1'b1;
            end else begin 
                if (count == 5'h01) begin 
                    reg_a   <= a;
                    reg_b   <= b;
                    reg_x   <= {2'b1,x0,16'b0};
                end
                if (count != 0)     count   <= count + 5'b1;
                if (count == 5'h0f) busy    <= 0;
                if (count == 5'h10) count   <= 5'b0;
                if ( (count == 5'h06) ||
                     (count == 5'h0b) ||
                     (count == 5'h10) )
                     reg_x  <= x52[50:25];    
            end
        end
    end
    assign          stall   = fdiv & (count == 0) | busy;
    wallace_26x24_product   bxxi (
        .a(reg_b), 
        .b(reg_x), 
        .z(bxi)
    );
    wire    [25:0]  b26     = ~bxi[48:23] + 1'b1;
    wallace_26x26_product   xip1 (
        .a(reg_x),
        .b(b26),
        .z(x52)
    );
    reg     [25:0]  reg_de_x;
    reg     [23:0]  reg_de_a;
    wire    [49:0]  m_s;
    wire    [49:8]  m_c;
    wallace_24x26           wt (
        .a(reg_de_a),
        .b(reg_de_x),
        .x(m_s[49:8]),
        .y(m_c),
        .z(m_s[7:0])
    );
    reg     [49:0]  a_s;
    reg     [49:8]  a_c;
    assign          d_x = {1'b0,a_s} + {a_c,8'b0};
    assign          e2p = {d_x[48:18],|d_x[17:0]};
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            reg_de_x    <= 0;           reg_de_a    <= 0;
            a_s         <= 0;           a_c         <= 0;
            q           <= 0;
        end else if (ena) begin 
            reg_de_x    <= x52[50:25];  reg_de_a    <= reg_a;
            a_s         <= m_s;         a_c         <= m_c;
            q           <= e2p;
        end
    end
    function    [7:0]   rom;
        input   [3:0]   b;
        case (b)
            4'h0: rom = 8'hff;          4'h1: rom = 8'hdf;
            4'h2: rom = 8'hc3;          4'h3: rom = 8'haa;
            4'h4: rom = 8'h93;          4'h5: rom = 8'h7f;
            4'h6: rom = 8'h6d;          4'h7: rom = 8'h5c;
            4'h8: rom = 8'h4d;          4'h9: rom = 8'h3f;
            4'ha: rom = 8'h33;          4'hb: rom = 8'h27;
            4'hc: rom = 8'h1c;          4'hd: rom = 8'h12;
            4'he: rom = 8'h08;          4'hf: rom = 8'h00;
        endcase
    endfunction
endmodule