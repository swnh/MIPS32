module fpu (
    input               clk, clrn,
    input       [31:0]  a, b,
    input       [4:0]   fd,
    input       [2:0]   fc,
    input               wf,
    input               ein1,
    input               ein2,
    output  reg [31:0]  wd,
    output      [31:0]  ed,
    output      [4:0]   count_div, count_sqrt,
    output  reg [4:0]   e1n, e2n, e3n, wn,
    output  reg [1:0]   e1c, e2c, e3c,
    output              e1w, 
    output  reg         e2w, e3w, ww,
    output              st_ds,
    output              e
);
//  reg             wd;
    reg     [31:0]  efa, efb;
//  reg             e1n, e2n, e3n, wn;
//  reg             e1c, e2c, e3c;
//  reg             e1w0, e2w, e3w, ww, sub;
    reg             e1w0, sub;
    wire    [31:0]  s_add, s_mul, s_div, s_sqrt;
    wire    [25:0]  reg_x_div, reg_x_sqrt;
    wire            fdiv    = fc[2] & ~fc[1];
    wire            fsqrt   = fc[2] &  fc[1];
    assign          e1w     = e1w0 & ein2;
    assign          e       = ein1 & ~st_ds;

    pipelined_fadder    f_add (
        // input ports
        .clk(clk),              .clrn(clrn),
        .a(efa),                .b(efb),
        .rm(2'b0),              .sub(sub),
        .e(e),                  
        // output port
        .s(s_add)
    );
    pipelined_fmul      f_mul (
        // input ports
        .clk(clk),              .clrn(clrn),
        .a(efa),                .b(efb),
        .rm(2'b0),              .e(e),
        // output port
        .s(s_mul)
    );
    fdiv_newton         f_div (
        // input ports
        .clk(clk),              .clrn(clrn),
        .a(a),                  .b(b),
        .rm(2'b0),              .fdiv(fdiv),
        .ena(e),                
        // output ports
        .s(s_div),              .reg_x(reg_x_div),               
        .count(count_div),      .busy(busy_div),
        .stall(stall_div)
    );
    fsqrt_newton       f_sqrt (
        // input ports
        .clk(clk),              .clrn(clrn),
        .d(a),                  .rm(2'b0),
        .fsqrt(fsqrt),          .ena(e),
        // output ports
        .s(s_sqrt),             .reg_x(reg_x_sqrt),
        .count(count_sqrt),     .busy(busy_sqrt),
        .stall(stall_sqrt)
    );

    assign          st_ds   = stall_div | stall_sqrt;
    mux4x32             fsel (
        // input ports
        .a0(s_add),             .a1(s_mul),
        .a2(s_div),             .a3(s_sqrt),
        .s(e3c),
        // output port
        .y(ed)
    );
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            sub <= 0;       efa  <= 0;       efb <= 0;
            e1c <= 0;       e1w0 <= 0;       e1n <= 0;
            e2c <= 0;       e2w  <= 0;       e2n <= 0;
            e3c <= 0;       e3w  <= 0;       e3n <= 0;
            wd  <= 0;       ww   <= 0;       wn  <= 0;
        end else if (e) begin 
            sub <= fc[0];   efa  <= a;       efb <= b;
            e1c <= fc[2:1]; e1w0 <= wf;      e1n <= fd;
            e2c <= e1c;     e2w  <= e1w;     e2n <= e1n;
            e3c <= e2c;     e3w  <= e2w;     e3n <= e2n;
            wd  <= ed;      ww   <= e3w;     wn  <= e3n;    
        end
    end
endmodule