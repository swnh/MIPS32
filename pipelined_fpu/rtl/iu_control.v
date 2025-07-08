module iu_control (
    input       [5:0]   op, func,
    input       [4:0]   rs, rt, fs, ft,
    input       [4:0]   ern, mrn,
    input       [4:0]   e1n, e2n, e3n,
    input               e1w, e2w, e3w,
    input               ewreg, em2reg, ewfpr,
    input               mwreg, mm2reg, mwfpr,
    input               stall_div_sqrt, st,
    input               rsrtequ,
    output              wpcir, wreg, m2reg, wmem,
    output              jal, aluimm, shift, sext, regrt,
    output              swfp, fwdf, fwdfe,
    output              fwdla, fwdlb, fwdfa, fwdfb,
    output              wfpr, wf, fasmds,
    output      [3:0]   aluc,
    output      [2:0]   fc,
    output      [1:0]   pcsrc, 
    output  reg [1:0]   fwda, fwdb,
    output              stall_lw, stall_fp, stall_lwc1, stall_swc1
);
    // Instruction Decode
    // R-type
    wire            rtype   = (op == 6'b000000);
    wire            i_add   = rtype & (func == 6'b100000);
    wire            i_sub   = rtype & (func == 6'b100010);
    wire            i_and   = rtype & (func == 6'b100100);
    wire            i_or    = rtype & (func == 6'b100101);
    wire            i_xor   = rtype & (func == 6'b100110);
    wire            i_sll   = rtype & (func == 6'b000000);
    wire            i_srl   = rtype & (func == 6'b000010);
    wire            i_sra   = rtype & (func == 6'b000011);
    wire            i_jr    = rtype & (func == 6'b001000);
    // I-type
    wire            i_addi  = (op == 6'b001000);
    wire            i_andi  = (op == 6'b001100);
    wire            i_ori   = (op == 6'b001101);
    wire            i_xori  = (op == 6'b001110);
    wire            i_lw    = (op == 6'b100011);
    wire            i_sw    = (op == 6'b101011);
    wire            i_beq   = (op == 6'b000100);
    wire            i_bne   = (op == 6'b000101);
    wire            i_lui   = (op == 6'b001111);
    // J-type
    wire            i_j     = (op == 6'b000010);
    wire            i_jal   = (op == 6'b000011);
    // F-type
    wire            ftype   = (op == 6'b010001);
    wire            i_fadd  = ftype & (func == 6'b000000);
    wire            i_fsub  = ftype & (func == 6'b000001);
    wire            i_fmul  = ftype & (func == 6'b000010);
    wire            i_fdiv  = ftype & (func == 6'b000011);
    wire            i_fsqrt = ftype & (func == 6'b000100);
    wire            i_lwc1  = (op == 6'b110001);
    wire            i_swc1  = (op == 6'b111001);
    wire            i_rs    = i_add  | i_sub | i_and  | i_or  | i_xor  | i_jr |
                              i_addi |         i_andi | i_ori | i_xori |
                              i_lw   | i_sw  | i_beq  | i_bne | i_lwc1 | i_swc1;
    wire            i_rt    = i_add  | i_sub | i_and  | i_or  | i_xor  |
                              i_sll  | i_srl | i_sra  | i_sw  | i_beq  | i_bne;
    assign      stall_lw    = ewreg & em2reg & (ern != 0) & 
                              (i_rs & (ern == rs) | i_rt & (ern == rt));
//  reg     [1:0]   fwda, fwdb;
    always @ (ewreg or mwreg or ern or mrn or em2reg or mm2reg or rs or rt) begin
        fwda = 2'b00;                                 // default: no hazards
        if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) begin
            fwda = 2'b01;                             // select exe_alu
        end else begin
            if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg) begin
                fwda = 2'b10;                         // select mem_alu
            end else begin
                if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg) begin
                    fwda = 2'b11;                     // select mem_lw
                end 
            end
        end
        fwdb = 2'b00;                                 // default: no hazards
        if (ewreg & (ern != 0) & (ern == rt) & ~em2reg) begin
            fwdb = 2'b01;                             // select exe_alu
        end else begin
            if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg) begin
                fwdb = 2'b10;                         // select mem_alu
            end else begin
                if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg) begin
                    fwdb = 2'b11;                     // select mem_lw
                end 
            end
        end
    end 

    assign          wreg    = (i_add | i_sub  | i_and  | i_or   | i_xor  | i_sll  |
                               i_srl | i_sra  | i_addi | i_andi | i_ori  | i_xori |
                               i_lw  | i_lui  | i_jal) & wpcir;
    assign          regrt   = i_addi | i_andi | i_ori  | i_xori | i_lw   | i_lui  | i_lwc1;
    assign          jal     = i_jal;
    assign          m2reg   = i_lw;
    assign          shift   = i_sll  | i_srl  | i_sra;
    assign          aluimm  = i_addi | i_andi | i_ori  | i_xor  | i_lw   | i_lui  | i_sw  |
                              i_lwc1 | i_swc1;
    assign          sext    = i_addi | i_lw   | i_sw   | i_beq  | i_bne  | i_lwc1 | i_swc1;
    assign          aluc[3] = i_sra;
    assign          aluc[2] = i_sub  | i_or   | i_srl  | i_sra  | i_ori  | i_lui;
    assign          aluc[1] = i_xor  | i_sll  | i_srl  | i_sra  | i_xori | i_beq  | i_bne | i_lui;
    assign          aluc[0] = i_and  | i_or   | i_sll  | i_srl  | i_sra  | i_andi | i_ori;
    assign          wmem    = (i_sw  | i_swc1) & wpcir;
    assign          pcsrc[1]= i_jr   | i_j    | i_jal;
    assign          pcsrc[0]= i_beq & rsrtequ | i_bne & ~rsrtequ | i_j | i_jal;
    // 000 fadd, 001 fsub, 01x fmul, 10x fdiv, 11x fsqrt
    wire    [2:0]   fop;
    assign          fop[2]  = i_fdiv | i_fsqrt;
    assign          fop[1]  = i_fmul | i_fsqrt;
    assign          fop[0]  = i_fsub;
    // stall caused by fp data hazards
    wire            i_fs    = i_fadd | i_fsub | i_fmul | i_fdiv | i_fsqrt;
    wire            i_ft    = i_fadd | i_fsub | i_fmul | i_fdiv;
    assign      stall_fp    = (e1w & (i_fs & (e1n == fs) | i_ft & (e1n == ft))) |
                              (e2w & (i_fs & (e2n == fs) | i_ft & (e2n == ft)));
    assign          fwdfa   = e3w & (e3n == fs);
    assign          fwdfb   = e3w & (e3n == ft);
    assign          wfpr    = i_lwc1 & wpcir;
    assign          fwdla   = mwfpr & (mrn == fs);
    assign          fwdlb   = mwfpr & (mrn == ft);
    assign      stall_lwc1  = ewfpr & (i_fs & (ern == fs) | i_ft & (ern == ft));
    assign          swfp    = i_swc1;
    assign          fwdf    = swfp & e3w & (ft == e3n);
    assign          fwdfe   = swfp & e2w & (ft == e2n);
    assign      stall_swc1  = swfp & e1w & (ft == e1n);
    wire        stall_others= stall_lw | stall_fp | stall_lwc1 | stall_swc1 | st;
    assign          wpcir   = ~(stall_div_sqrt | stall_others);
    assign          fc      = fop & {3{~stall_others}};
    assign          wf      = i_fs & wpcir;
    assign          fasmds  = i_fs;
endmodule