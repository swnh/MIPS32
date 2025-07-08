module cpu_cache_tlb_memory (
    input               clk,
    input               memclk,
    input               clrn,
    output      [31:0]  v_pc,
    output      [31:0]  pc,
    output      [31:0]  inst,
    output      [31:0]  ealu,
    output      [31:0]  malu,
    output      [31:0]  wdi,
    output      [31:0]  wd,
    output      [4:0]   wn,
    output              ww,
    output              stall_lw,
    output              stall_fp,
    output              stall_lwc1,
    output              stall_swc1,
    output              stall,
    output      [31:0]  m_a,
    output      [31:0]  m_d_r,
    output      [31:0]  m_d_w,
    output              m_access,
    output              m_write,
    output              m_ready
);
    wire                io;
    // cpu
    cpu_cache_tlb   cpucachetlb(
        // input ports
        .clk(clk),                  .clrn(clrn),
        .memclk(memclk),
        .mem_data(m_d_r),           .mem_ready(m_ready),
        // output ports
        .v_pc(v_pc),                .pc(pc),
        .inst(inst),
        .ealu(ealu),                .malu(malu),
        .wdi(wdi),                  .wd(wd),
        .mem_a(m_a),                .mem_st_data(m_d_w),
        .wn(wn),                    .ww(ww),
        .stall_lw(stall_lw),        .stall_fp(stall_fp),
        .stall_lwc1(stall_lwc1),    .stall_swc1(stall_swc1),
        .stall(stall),
        .mem_access(m_access),      .mem_write(m_write),
        .io(io)
    );

    // i/o, ignored
    wire        [31:0]  io_d_r   = 0;
    wire                io_ready = 1;
    wire        [31:0]  mem_d_r;
    wire                mem_ready;
    wire                mem_access  = m_access & ~io;
    wire                io_access   = m_access &  io;
    wire                mem_write   = m_write  & ~io;
    wire                io_write    = m_write  &  io;
    assign              m_d_r       = io ? io_d_r   : mem_d_r;
    assign              m_ready     = io ? io_ready : mem_ready;

    // main memory
    physical_memory mem (
        // input ports
        .clk(clk),          .clrn(clrn),
        .memclk(memclk),
        .a(m_a),            .din(m_d_w),
        .strobe(mem_access),.rw(m_write),
        // output ports
        .dout(mem_d_r),     .ready(mem_ready) 
    );
endmodule