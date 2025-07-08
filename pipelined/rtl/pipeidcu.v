// The circuit for control unit in ID stage
module pipeidcu (
    input   [5:0]   op, func,
    input   [4:0]   rs, rt,
    input   [4:0]   ern,
    input   [4:0]   mrn,
    input           ewreg,
    input           em2reg,
    input           mwreg,
    input           mm2reg,
    input           rsrtequ,
    output  [3:0]   aluc,
    output  [1:0]   pcsrc,
    output  [1:0]   fwda,
    output  [1:0]   fwdb,
    output          wreg,
    output          m2reg,
    output          wmem,
    output          aluimm,
    output          shift,
    output          jal,
    output          regrt,
    output          sext,
    output          nostall
);

    // Instruction Decode
    // R-format
    wire    i_add   = (op == 6'b000000) & (func == 6'b100000);
    wire    i_sub   = (op == 6'b000000) & (func == 6'b100010);
    wire    i_and   = (op == 6'b000000) & (func == 6'b100100);
    wire    i_or    = (op == 6'b000000) & (func == 6'b100101);
    wire    i_xor   = (op == 6'b000000) & (func == 6'b100110);
    wire    i_sll   = (op == 6'b000000) & (func == 6'b000000);
    wire    i_srl   = (op == 6'b000000) & (func == 6'b000010);
    wire    i_sra   = (op == 6'b000000) & (func == 6'b000011);
    wire    i_jr    = (op == 6'b000000) & (func == 6'b001000);
    // I-format
    wire    i_addi  = (op == 6'b001000);
    wire    i_andi  = (op == 6'b001100);
    wire    i_ori   = (op == 6'b001101);
    wire    i_xori  = (op == 6'b001110);
    wire    i_lw    = (op == 6'b100011);
    wire    i_sw    = (op == 6'b101011);
    wire    i_beq   = (op == 6'b000100);
    wire    i_bne   = (op == 6'b000101);
    wire    i_lui   = (op == 6'b001111);
    // J-format
    wire    i_j     = (op == 6'b000010);
    wire    i_jal   = (op == 6'b000011);    

    wire    i_rs    = i_add  | i_sub | i_and  | i_or | i_xor | i_jr  | i_addi |
                      i_andi | i_ori | i_xori | i_lw | i_sw  | i_beq | i_bne;
    wire    i_rt    = i_add  | i_sub | i_and  | i_or | i_xor | i_sll | i_srl  |
                      i_sra  | i_sw  | i_beq  | i_bne;
    assign  nostall = ~( ewreg & em2reg & (ern != 0) & ( i_rs & (ern == rs) | i_rt & (ern == rt) ) );
    
    reg [1:0] fwda, fwdb;
    always @(ewreg, mwreg, ern, mrn, em2reg, mm2reg, rs, rt) begin 
        fwda = 2'b00;
        if ( ewreg & (ern != 0) & (ern == rs) & ~em2reg ) begin
            fwda = 2'b01; // exe_alu
        end else if ( mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg ) begin 
            fwda = 2'b10; // mem_alu
        end else if ( mwreg & (mrn != 0) & (mrn == rs) &  mm2reg ) begin 
            fwda = 2'b11; // mem_lw
        end

        fwdb = 2'b00;
        if ( ewreg & (ern != 0) & (ern == rt) & ~em2reg ) begin
            fwdb = 2'b01; // exe_alu
        end else if ( mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg ) begin 
            fwdb = 2'b10; // mem_alu
        end else if ( mwreg & (mrn != 0) & (mrn == rt) &  mm2reg ) begin 
            fwdb = 2'b11; // mem_lw
        end
    end

    // control signals
    assign  wreg     = (i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl |
                        i_sra | i_addi| i_andi| i_ori| i_xori| i_lw  | i_lui |
                        i_jal) & nostall;
    assign  regrt    = i_addi| i_andi| i_ori | i_xori| i_lw | i_lui;
    assign  jal      = i_jal;
    assign  m2reg    = i_lw;
    assign  shift    = i_sll | i_srl | i_sra;
    assign  aluimm   = i_addi| i_andi| i_ori| i_xori| i_lw | i_lui | i_sw; 
    assign  sext     = i_addi| i_lw  | i_sw | i_beq | i_bne;
    assign  aluc[3]  = i_sra;
    assign  aluc[2]  = i_sub | i_or  | i_srl| i_sra | i_ori | i_lui;
    assign  aluc[1]  = i_xor | i_sll | i_srl| i_sra | i_xori| i_beq | i_bne | i_lui;
    assign  aluc[0]  = i_and | i_or  | i_sll| i_srl | i_sra | i_andi| i_ori ;
    assign  wmem     = i_sw & nostall;
    assign  pcsrc[1] = i_jr  | i_j   | i_jal;
    assign  pcsrc[0] = i_beq & rsrtequ | i_bne & ~rsrtequ | i_j | i_jal;
endmodule