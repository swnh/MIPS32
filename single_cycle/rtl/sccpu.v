module sccpu (clk, clrn, inst, mem, pc, wmem, alu, data);   // single cycle cpu
    input   [31:0]  inst;                                   // inst from inst memory
    input   [31:0]  mem;                                    // data from data memory
    input           clk, clrn;                              // clock and clear
    output  [31:0]  pc;                                     // program counter
    output  [31:0]  alu;                                    // alu output
    output  [31:0]  data;                                   // data to data memory
    output          wmem;                                   // write data to memory

    // instruction fields
    wire    [5:0]   op   = inst[31:26];                     // op 6-bit
    wire    [4:0]   rs   = inst[25:21];                     // rs 5-bit
    wire    [4:0]   rt   = inst[20:16];                     // rt 5-bit
    wire    [4:0]   rd   = inst[15:11];                     // rd 5-bit
    wire    [5:0]   func = inst[05:00];                     // func 6-bit
    wire    [15:0]  imm  = inst[15:00];                     // immediate for I-type
    wire    [25:0]  addr = inst[25:00];                     // address for J-type

    // control signals
    wire    [3:0]   aluc;                                   // alu operation control
    wire    [1:0]   pcsrc;                                  // select pc source
    wire            wreg;                                   // write regfile
    wire            regrt;                                  // dest reg number is rt
    wire            m2reg;                                  // instruction is an lw
    wire            shift;                                  // instruction is a shift
    wire            aluimm;                                 // alu input b is an i32
    wire            jal;                                    // instruction is jal
    wire            sext;                                   // is sign extension (flag)

    // datapath wires
    wire    [31:0]  p4;                                     // pc + 4
    wire    [31:0]  bpc;                                    // branch target address
    wire    [31:0]  npc;                                    // next pc
    wire    [31:0]  qa;                                     // regfile output for port a
    wire    [31:0]  qb;                                     // regfile ouptut for port b
    wire    [31:0]  alua;                                   // alu input a
    wire    [31:0]  alub;                                   // alu input b
    wire    [31:0]  wd;                                     // regfile write port data
    wire    [31:0]  r;                                      // alu out or mem
    wire    [31:0]  sa  = {27'b0,inst[10:6]};               // shift amount, why set to 32-bit?
    wire    [15:0]  s16 = {16{sext & inst[15]}};            // 16-bit signs
    wire    [31:0]  i32 = {s16,imm};                        // 32-bit immediate with sign extension
    wire    [31:0]  dis = {s16[13:0],imm,2'b00};            // word distance, for what?
    wire    [31:0]  jpc = {p4[31:28],addr,2'b00};           // jump target address
    wire    [4:0]   reg_dest;                               // rs or rt
    wire    [4:0]   wn  = reg_dest | {5{jal}};              // regfile write reg #
    wire            z;                                      // alu, zero tag

    // control unit
    sccu_dataflow cu (
        .op(op),
        .func(func),
        .z(z),
        .wmem(wmem),
        .wreg(wreg),
        .regrt(regrt),
        .m2reg(m2reg),
        .aluc(aluc),
        .shift(shift),
        .aluimm(aluimm),
        .pcsrc(pcsrc),
        .jal(jal),
        .sext(sext)
    );

    // datapath
    // pc register
    dff32 i_point (
        .d(npc),
        .clk(clk),
        .clrn(clrn),
        .q(pc)
    );
    // pc + 4
    cla32 pcplus4 (
        .a(pc),
        .b(32'h4),
        .ci(1'b0),
        .s(p4)
    );
    // branch target address
    cla32 br_addr(
        .a(p4),
        .b(dis),
        .ci(1'b0),
        .s(bpc)
    );
    // alu input a
    mux2x32 alu_a(
        .a0(qa),
        .a1(sa),
        .s(shift),
        .y(alua)
    );
    // alu input b
    mux2x32 alu_b(
        .a0(qb),
        .a1(i32),
        .s(aluimm),
        .y(alub)
    );
    // alu out or mem
    mux2x32 alu_m(
        .a0(alu),
        .a1(mem),
        .s(m2reg),
        .y(r)
    );
    // r or p4
    mux2x32 link (
        .a0(r),
        .a1(p4),
        .s(jal),
        .y(wd)
    );
    // rs or rt
    mux2x5 reg_wn (
        .a0(rd),
        .a1(rt),
        .s(regrt),
        .y(reg_dest)
    );
    // next pc
    mux4x32 nextpc (
        .a0(p4),
        .a1(bpc),
        .a2(qa),
        .a3(jpc),
        .s(pcsrc),
        .y(npc)
    );
    // register file
    regfile rf (
        .rna(rs),
        .rnb(rt),
        .d(wd),
        .wn(wn),
        .we(wreg),
        .clk(clk),
        .clrn(clrn),
        .qa(qa),
        .qb(qb)
    );
    // alu
    alu alunit (
        .a(alua),
        .b(alub),
        .aluc(aluc),
        .r(alu),
        .z(z)
    );
    assign data = qb;                                               // regfile output port b
endmodule