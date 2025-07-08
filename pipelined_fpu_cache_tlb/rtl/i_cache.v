module i_cache (
    input       [31:0]  p_a,
    output      [31:0]  p_din,
    input               p_strobe,
    input               uncached,
    output              p_ready,
    output              cache_miss,
    input               clk, clrn,
    output      [31:0]  m_a,
    input       [31:0]  m_dout,
    output              m_strobe,
    input               m_ready  
);
    reg                 d_valid [0:63];
    reg         [23:0]  d_tags  [0:63];
    reg         [31:0]  d_data  [0:63];
    wire        [5:0]   index   = p_a[7:2];
    wire        [23:0]  tag     = p_a[31:8];
    wire                c_write;
    wire        [31:0]  c_din;

    integer i;
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            for (i=0; i<64; i=i+1) begin 
                d_valid[i] <= 0;
            end
        end else if (c_write) begin 
            d_valid[index] <= 1;
        end
    end

    always @(posedge clk) begin 
        if (c_write) begin 
            d_tags[index] <= tag;
            d_data[index] <= c_din;
        end
    end

    wire                valid   = d_valid[index];
    wire        [23:0]  tagout  = d_tags[index];
    wire        [31:0]  c_dout  = d_data[index];
    wire                cache_hit   = p_strobe & valid & (tagout == tag);
    assign              cache_miss  = p_strobe & (!valid | (tagout != tag));
    assign              m_a         = p_a;
    assign              m_strobe    = cache_miss;
    assign              p_ready     = cache_hit | cache_miss & m_ready;
    assign              c_write     = cache_miss & ~uncached & m_ready;
    assign              c_din       = m_dout;
    assign              p_din       = cache_hit ? c_dout : m_dout;
endmodule