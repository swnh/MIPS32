module physical_memory (
    input               clk, memclk, clrn,
    input       [31:0]  a,
    input       [31:0]  din,
    input               strobe,
    input               rw,
    output      [31:0]  dout,
    output reg          ready
);
    wire    [31:0]  mem_data_out0;
    wire    [31:0]  mem_data_out1;
    wire    [31:0]  mem_data_out2;
    wire    [31:0]  mem_data_out3;
    // for memory ready
    reg      [2:0]  wait_counter;
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            wait_counter <= 3'b0;
        end else begin 
            if (strobe) begin 
                if (wait_counter == 3'h5) begin
                    ready <= 1;
                    wait_counter <= 3'b0;
                end else begin 
                    ready <= 0;
                    wait_counter <= wait_counter + 3'b1;
                end
            end else begin 
                ready <= 0;
                wait_counter <= 3'b0;
            end
        end
    end
    wire    [31:0]  m_out32 = a[13] ? mem_data_out3 : mem_data_out2;
    wire    [31:0]  m_out10 = a[28] ? mem_data_out1 : mem_data_out0;
    wire    [31:0]  mem_out = a[29] ? m_out32       : m_out10;
    assign          dout    = ready ? mem_out       : 32'hzzzz_zzzz;
    wire            write_enable0   = ~a[29] & ~a[28] & rw;
    wire            write_enable1   = ~a[29] &  a[28] & rw;
    wire            write_enable2   =  a[29] & ~a[13] & rw;
    wire            write_enable3   =  a[29] &  a[13] & rw;
    wire    [31:0]  mem_data_out0_wire;
    wire    [31:0]  mem_data_out1_wire;
    wire    [31:0]  mem_data_out2_wire;
    wire    [31:0]  mem_data_out3_wire;
    // physical address 0x0000_0000 - 0x0000_01ff
    blk_mem_gen_0 ram0 (
        .addra(a[8:2]),
        .clka(memclk),
        .dina(din),
        .douta(mem_data_out0_wire),
        .wea(write_enable0)
    );
    // physical address 0x1000_0000 - 0x1000_01ff
    blk_mem_gen_1 ram1 (
        .addra(a[8:2]),
        .clka(memclk),
        .dina(din),
        .douta(mem_data_out1_wire),
        .wea(write_enable1)
    );
    // physical address 0x2000_0000 - 0x2000_01ff
    blk_mem_gen_2 ram2 (
        .addra(a[8:2]),
        .clka(memclk),
        .dina(din),
        .douta(mem_data_out2_wire),
        .wea(write_enable2)
    );
    // physical address 0x2000_2000 - 0x2000_21ff
    blk_mem_gen_3 ram3 (
        .addra(a[8:2]),
        .clka(memclk),
        .dina(din),
        .douta(mem_data_out3_wire),
        .wea(write_enable3)
    );
    
    reg     [31:0]  mem_data_out0_reg;
    reg     [31:0]  mem_data_out1_reg;
    reg     [31:0]  mem_data_out2_reg;
    reg     [31:0]  mem_data_out3_reg;
    always @(posedge memclk or negedge clrn) begin 
        if (!clrn) begin 
            mem_data_out0_reg   <= 0;
            mem_data_out1_reg   <= 0;
            mem_data_out2_reg   <= 0;
            mem_data_out3_reg   <= 0;
        end else begin 
            if (strobe) begin 
                mem_data_out0_reg   <= mem_data_out0_wire;
                mem_data_out1_reg   <= mem_data_out1_wire;
                mem_data_out2_reg   <= mem_data_out2_wire;
                mem_data_out3_reg   <= mem_data_out3_wire;
            end
        end
    end
    assign  mem_data_out0   = mem_data_out0_reg;
    assign  mem_data_out1   = mem_data_out1_reg;
    assign  mem_data_out2   = mem_data_out2_reg;
    assign  mem_data_out3   = mem_data_out3_reg;
endmodule