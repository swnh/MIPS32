module iu_cache_tlb (
    input               clk,
    input               memclk,
    input               clrn,
    input       [31:0]  mem_data,
    input               mem_ready,
    input       [31:0]  dfb,
    input       [31:0]  e3d,
    input       [4:0]   e1n, e2n, e3n,
    input               e1w, e2w, e3w,
    input               stall,
    input               st,
    output      [31:0]  v_pc,
    output      [31:0]  pc,
    output      [31:0]  inst,
    output      [31:0]  ealu,
    output  reg [31:0]  malu,
    output      [31:0]  wdi,
    output      [31:0]  mmo,
    output  reg [31:0]  wmo,
    output      [31:0]  mem_a,
    output      [31:0]  mem_st_data,
    output      [4:0]   fs, ft, fd,
    output  reg [4:0]   wrn,
    output      [2:0]   fc,
    output              mem_access,
    output              mem_write,
    output  reg         wwfpr,
    output              fwdla,
    output              fwdlb,
    output              fwdfa,
    output              fwdfb,
    output              wf,
    output              fasmds,
    output              stall_lw,
    output              stall_fp,
    output              stall_lwc1,
    output              stall_swc1,
    output              no_cache_stall,
    output              dtlb,
    output              io
);

    parameter           exc_base    = 32'h8000_0008;
    wire        [31:0]  bpc, jpc, npc, pc4, ins, dpc4, qa, qb, da, db, dc, dd;
    wire        [31:0]  simm, epc8, alua, alub, ealu0, ealu1, sa, eb;
    wire        [5:0]   op, func;
    wire        [4:0]   rs, rt ,rd, drn, ern;
    wire        [3:0]   aluc;
    wire        [1:0]   pcsrc, fwda, fwdb;
    wire                wpcir, wreg, m2reg, wmem, aluimm, shift, jal;
    reg                 ewfpr, ewreg, em2reg, ewmem, ejal, efwdfe, ealuimm, eshift;
    reg                 mwfpr, mwreg, mm2reg, mwmem;
    reg                 wwreg, wm2reg;
    reg         [31:0]  epc4, ea, ed, eimm, mb, walu;
    reg         [4:0]   ern0, mrn;
    reg         [3:0]   ealuc;
    wire        [23:0]  ipte_out;
    wire                itlb_hit;
    wire        [31:0]  pcd;
    wire        [31:0]  index;
    wire        [31:0]  entlo;
    reg         [31:0]  contx;
    wire        [31:0]  enthi;
    wire                windex, wentlo, wcontx, wenthi;
    wire                rc0, wc0;
    wire        [1:0]   c0rn;
    wire                swfp, regrt, sext, fwdf, fwdfe, wfpr;
    wire                i_ready, i_cache_miss;
    wire                tlbwi, tlbwr;
    wire                wepc, wcau, wsta, isbr, cancel, exce, ldst;
    wire        [1:0]   sepc, selpc;
    wire        [31:0]  sta, cau, epc, sta_in, cau_in, epc_in;
    wire        [31:0]  stalr, epcin, cause, c0reg, next_pc;
    reg         [31:0]  pce;
    reg         [1:0]   ec0rn;
    reg                 erc0, ecancel, eisbr, eldst;
    reg         [31:0]  pcm;
    reg                 misbr, mldst;
    wire        [23:0]  dpte_out;
    wire                dtlb_hit;
    reg         [31:0]  pcw;
    reg                 wisbr;
    wire                m_fetch, m_ld_st, m_st;
    wire        [31:0]  m_i_a, m_d_a;
    wire                itlb_exc, dtlb_exc;
    wire                itlb_exce, dtlb_exce;
    wire                m_i_ready;
    wire                m_d_ready;

    // IF stage
    vpc         v_p_c (
        .clk(clk),
        .clrn(clrn),
        .d(next_pc),
        .e(wpcir & no_cache_stall),
        .q(v_pc)
    );
//  cla32   pc_plus4 (v_pc, 32'h4, 1'b0, pc4);
    assign              pc4 = v_pc + 32'h4;
    mux4x32     nextpc (pc4, bpc, da, jpc, pcsrc, npc);
    wire                itlbwi  = tlbwi & ~index[30];
    wire                itlbwr  = tlbwi & ~index[30];
    wire                dtlbwi  = tlbwi &  index[30];
    wire                dtlbwr  = tlbwr &  index[30];
    wire        [19:0]  ipattern    = (itlbwi | itlbwr) ? enthi[19:0] : v_pc[31:12];
    wire                pc_unmapped = v_pc[31] & ~v_pc[30];
    wire                pc_uncached = pc_unmapped & v_pc[29];
    assign              pc  = pc_unmapped ? {3'b0,v_pc[28:0]} : {ipte_out[19:0],v_pc[11:0]};

    tlb_8_entry itlb (
        .pte_in(entlo[23:0]),
        .tlbwi(itlbwi),         .tlbwr(itlbwr),
        .index(index[2:0]),     .vpn(ipattern),
        .clk(clk),              .clrn(clrn),
        .pte_out(ipte_out),     .tlb_hit(itlb_hit)
    );
    assign              itlb_exc    = ~itlb_hit & ~pc_unmapped;
    i_cache     icache (
        // input ports          // output ports
        .p_a(pc),               .p_din(ins),
        .p_strobe(1'b1),
        .uncached(pc_uncached), .p_ready(i_ready),
                                .cache_miss(i_cache_miss),
        .clk(clk),              
        .clrn(clrn),            .m_a(m_i_a),
        .m_dout(mem_data),
                                .m_strobe(m_fetch),
        .m_ready(m_i_ready)
    );

    // IF/ID pipeline registers
    dffe32      pc_4_r (pc4, clk, clrn, wpcir & no_cache_stall, dpc4);
    dffe32      inst_r (ins, clk, clrn, wpcir & no_cache_stall, inst);
    dffe32      pcd_r (v_pc, clk, clrn, wpcir & no_cache_stall, pcd);

    // ID stage
    assign              op   = inst[31:26];
    assign              rs   = inst[25:21];
    assign              rt   = inst[20:16];
    assign              rd   = inst[15:11];
    assign              ft   = inst[20:16];
    assign              fs   = inst[15:11];
    assign              fd   = inst[10:6];
    assign              func = inst[5:0];
    assign              simm = {{16{sext&inst[15]}}, inst[15:0]};
    assign              jpc  = {dpc4[31:28],inst[25:0],2'b00};
//  cla32       br_addr (dpc4, {simm[29:0],2'b00},1'b0, bpc);
    assign              bpc  = dpc4 + {simm[29:0],2'b00};
    regfile     rf (rs, rt, wdi, wrn, wwreg, ~clk, clrn, qa, qb);
    mux4x32     alu_a (qa, ealu, malu, mmo, fwda, da);
    mux4x32     alu_b (qb, ealu, malu, mmo, fwdb, db);
    mux2x32     store_f (db, dfb, swfp, dc);
    mux2x32     fwd_f_d (dc, e3d, fwdf, dd);
    wire                rsrtequ = ~|(da^db);
    mux2x5      des_reg_no (rd, rt, regrt, drn);
    iu_cache_tlb_cu cu (
        .op(op),                .func(func),
        .rs(rs),                .rt(rt),
        .rd(rd),                .rsrtequ(rsrtequ),
        .fs(fs),                .ft(ft),
        .ewfpr(ewfpr),          .ewreg(ewreg),
        .em2reg(em2reg),        .ern(ern),
        .mwfpr(mwfpr),          .mwreg(mwreg),
        .mm2reg(mm2reg),        .mrn(mrn),
        .e1w(e1w),              .e1n(e1n),
        .e2w(e2w),              .e2n(e2n),
        .e3w(e3w),              .e3n(e3n),
        .stall_div_sqrt(stall), .st(st),
        .pcsrc(pcsrc),          .wpcir(wpcir),
        .wreg(wreg),            .m2reg(m2reg),
        .wmem(wmem),            .jal(jal),
        .aluc(aluc),            .sta(sta),
        .aluimm(aluimm),        .shift(shift),
        .sext(sext),            .regrt(regrt),
        .fwda(fwda),            .fwdb(fwdb),
        .swfp(swfp),            .fwdf(fwdf),
        .fwdfe(fwdfe),          .wfpr(wfpr),
        .fwdla(fwdla),          .fwdlb(fwdlb),
        .fwdfa(fwdfa),          .fwdfb(fwdfb),
        .fc(fc),                .wf(wf),
        .fasmds(fasmds),        
        .stall_lw(stall_lw),    .stall_fp(stall_fp),    
        .stall_lwc1(stall_lwc1),.stall_swc1(stall_swc1),
        .windex(windex),        .wentlo(wentlo),
        .wcontx(wcontx),        .wenthi(wenthi),        
        .rc0(rc0),              .wc0(wc0),
        .tlbwi(tlbwi),          .tlbwr(tlbwr),
        .c0rn(c0rn),            .wepc(wepc),
        .wcau(wcau),            .wsta(wsta),
        .isbr(isbr),            .sepc(sepc),
        .cancel(cancel),        .cause(cause),
        .exce(exce),            .selpc(selpc),
        .ldst(ldst),            .wisbr(wisbr),
        .ecancel(ecancel),      
        .itlb_exc(itlb_exc),    .dtlb_exc(dtlb_exc),
        .itlb_exce(itlb_exce),  .dtlb_exce(dtlb_exce)    
    );
    assign              dtlb    = ~dtlb_exce;
    dffe32      c0_Index (db, clk, clrn, windex & no_cache_stall, index);
    dffe32      c0_EntLo (db, clk, clrn, wentlo & no_cache_stall, entlo);
    dffe32      c0_EntHi (db, clk, clrn, wenthi & no_cache_stall, enthi);

    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            contx <= 0;
        end else begin
            if (wcontx) begin
                contx[31:22] <= db[31:22];
            end
            if (itlb_exce) begin
                contx[21:0]  <= {v_pc[31:12],2'b00};
            end else if (dtlb_exce) begin 
                contx[21:0]  <= {malu[31:12],2'b00};
            end
        end
    end
    dffe32      c0_Status (sta_in, clk, clrn, wsta & no_cache_stall, sta);
    dffe32      c0_Cause (cau_in, clk, clrn, wcau & no_cache_stall, cau);
    dffe32      c0_epc (epc_in, clk, clrn, wepc & no_cache_stall, epc);
    mux2x32     sta_mx (stalr, db, wc0, sta_in);
    mux2x32     cau_mx (cause, db, wc0, cau_in);
    mux2x32     epc_mx (epcin, db, wc0, epc_in);
    mux2x32     sta_lr ({8'h0,sta[31:8]},{sta[23:0],8'h0},exce,stalr);
    mux4x32     epc_04 (v_pc, pcd, pcm, pcw, sepc, epcin);
    mux4x32     irq_pc (npc, epc, exc_base, 32'h0, selpc, next_pc);
    mux4x32     fromc0 (contx, sta, cau, epc, ec0rn, c0reg);

    // ID/EXE pipeline registers
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin
            ewfpr   <= 0;       ewreg   <= 0;
            eldst   <= 0;       ewmem   <= 0;
            ejal    <= 0;       ealuimm <= 0;
            efwdfe  <= 0;       ealuc   <= 0;
            eshift  <= 0;       epc4    <= 0;
            ea      <= 0;       ed      <= 0;
            eimm    <= 0;       ern0    <= 0;
            erc0    <= 0;       ec0rn   <= 0;
            ecancel <= 0;       eisbr   <= 0;
            pce     <= 0;       em2reg  <= 0;
        end else if (no_cache_stall) begin 
            ewfpr   <= wfpr;    ewreg   <= wreg;
            eldst   <= ldst;    ewmem   <= wmem;
            ejal    <= jal;     ealuimm <= aluimm;
            efwdfe  <= fwdfe;   ealuc   <= aluc;
            eshift  <= shift;   epc4    <= dpc4;
            ea      <= da;      ed      <= dd;
            eimm    <= simm;    ern0    <= drn;
            erc0    <= rc0;     ec0rn   <= c0rn;
            ecancel <= cancel;  eisbr   <= isbr;
            pce     <= pcd;     em2reg  <= m2reg;
        end
    end

    // EXE stage
//  cla32   ret_addr (epc4, 32'h4, 1'b0, epc8);
    assign              epc8= epc4 + 32'h4;
    assign              sa  = {eimm[5:0],eimm[31:6]};
    mux2x32     alu_ina (ea, sa, eshift, alua);
    mux2x32     alu_inb (eb, eimm, ealuimm, alub);
    mux2x32     save_pc8 (ealu0, epc8, ejal, ealu1);
    mux2x32     read_cr0 (ealu1, c0reg, erc0, ealu);
    wire                z;
    alu         al_unit (alua, alub, ealuc, ealu0, z);
    assign              ern = ern0 | {5{ejal}};
    mux2x32     fwd_f_e (ed, e3d, efwdfe, eb);

    // EXE/MEM pipeline registers
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin
            mwfpr   <= 0;       mwreg   <= 0;
            mldst   <= 0;       mwmem   <= 0;
            malu    <= 0;       mb      <= 0;
            mrn     <= 0;       misbr   <= 0;
            pcm     <= 0;       mm2reg  <= 0;
        end else if (no_cache_stall) begin 
            mwfpr   <= ewfpr & ~dtlb_exce;      // cancel exe
            mwreg   <= ewreg & ~dtlb_exce;      // cancel exe
            mwmem   <= ewmem & ~dtlb_exce;      // cancel exe
            mldst   <= eldst & ~dtlb_exce;      // cancel exe
            malu    <= ealu;    mb      <= eb;
            mrn     <= ern;     misbr   <= eisbr;
            pcm     <= pce;     mm2reg  <= em2reg; 
        end
    end

    // MEM stage
    wire    [19:0]  dpattern    = (dtlbwi | dtlbwr) ? enthi[19:0] : malu[31:12];
    wire            ma_unmapped = malu[31] & ~malu[30];     // 10xx...xx
    wire            ma_uncached = ma_unmapped & malu[29];   // 101x...xx
    wire    [31:0]  m_addr      = ma_unmapped ? {3'b0,malu[28:0]} : {dpte_out[19:0],malu[11:0]};
    tlb_8_entry d_tlb (
        .pte_in(entlo[23:0]),
        .tlbwi(dtlbwi),         .tlbwr(dtlbwr),
        .index(index[2:0]),     .vpn(dpattern),
        .clk(clk),              .clrn(clrn),
        .pte_out(dpte_out),     .tlb_hit(dtlb_hit)
    );
    assign          dtlb_exc    = ~dtlb_hit & ~ma_unmapped & mldst;
    wire            d_ready;
    wire            w_mem       = mwmem & ~dtlb_exce;   // cancel mem (sw/swc1)
    d_cache     dcache(
        // input ports          // output ports
        .p_a(m_addr),
        .p_dout(mb),            .p_din(mmo),
        .p_strobe(mldst),
        .p_rw(w_mem),
        .uncached(ma_uncached), .p_ready(d_ready),
        .clk(clk),
        .clrn(clrn),            .m_a(m_d_a),
        .m_dout(mem_data),      .m_din(mem_st_data),
                                .m_strobe(m_ld_st),
                                .m_rw(m_st),
        .m_ready(m_d_ready)
    );
    assign          io          = pc_uncached | ma_uncached;

    // MEM/WB pipeline registers
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin
            wwfpr   <= 0;       wwreg   <= 0;
            wm2reg  <= 0;       wmo     <= 0;
            walu    <= 0;       wrn     <= 0;
            pcw     <= 0;       wisbr   <= 0;
        end else if (no_cache_stall) begin 
            wwfpr   <= mwfpr & ~dtlb_exce;      // cancel mem
            wwreg   <= mwreg & ~dtlb_exce;      // cancel mem
            wm2reg  <= mm2reg;  wmo     <= mmo;
            walu    <= malu;    wrn     <= mrn;
            pcw     <= pcm;     wisbr   <= misbr;      
        end
    end     

    // WB stage
    mux2x32     wb_sel (walu, wmo, wm2reg, wdi);
    // mux, i_cache has higher priority than d_cache
    wire            sel_i       = i_cache_miss;
    assign          mem_a       = sel_i ? m_i_a     : m_d_a;
    assign          mem_access  = sel_i ? m_fetch   : m_ld_st;
    assign          mem_write   = sel_i ? 1'b0      : m_st;
    // demux the main mem ready
    assign          m_i_ready   = mem_ready &  sel_i;
    assign          m_d_ready   = mem_ready & ~sel_i;
    assign          no_cache_stall  = ~(~i_ready & ~itlb_exce | 
                                mldst & ~d_ready & ~dtlb_exce );   
endmodule