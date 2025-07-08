module sccpu(
    input               clk,
    input               clrn,
    input       [31:0]  mem,
    input       [31:0]  inst,
    output  reg [31:0]  pc,
    output  reg [31:0]  alu,
    output      [31:0]  data,
    output  reg         wmem
); 

    reg             wreg;
    reg     [4:0]   dest_rn;
    reg     [31:0]  next_pc;
    wire    [31:0]  pc4 = pc + 4;

    // Instruction Field
    wire    [5:0]   op   = inst[31:26];
    wire    [4:0]   rs   = inst[25:21];
    wire    [4:0]   rt   = inst[20:16];
    wire    [4:0]   rd   = inst[15:11];
    wire    [4:0]   sa   = inst[10:06];
    wire    [5:0]   func = inst[05:00];
    wire    [15:0]  imm  = inst[15:00];
    wire    [25:0]  addr = inst[25:00];
    wire            sign = inst[15];
    wire    [31:0]  offset = {{14{sign}},imm,2'b00};
    wire    [31:0]  j_addr = {pc4[31:28],addr,2'b00};

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

    // Program Counter
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            pc <= 0;
        end else begin 
            pc <= next_pc;
        end
    end

    // Data written into Register File
    wire    [31:0]  data_to_regfile = i_lw ? mem : alu;

    // Register File
    reg     [31:0]  regfile [1:31];
    wire    [31:0]  a = (rs == 0) ? 0 : regfile[rs];
    wire    [31:0]  b = (rt == 0) ? 0 : regfile[rt];

    integer i; // to initialize regfile or the error occurs
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            for (i = 1; i < 32; i = i + 1) begin
                regfile[i] <= 0;
            end 
        end else if (wreg && (dest_rn != 0)) begin 
            regfile[dest_rn] <= data_to_regfile;
        end
    end

    // Output signals
    assign  data    = b;

    // Control signals and ALU output will be combinational circuit
    always @(*) begin 
        alu     = 0;
        dest_rn = rd;
        wreg    = 0;
        wmem    = 0;
        next_pc = pc4;

        case (1'b1)
            i_add: begin 
                alu     = a + b;
                wreg    = 1;
            end

            i_sub: begin 
                alu     = a - b;
                wreg    = 1;
            end

            i_and: begin 
                alu     = a & b;
                wreg    = 1;
            end

            i_or: begin 
                alu     = a | b;
                wreg    = 1;
            end

            i_xor: begin 
                alu     = a ^ b;
                wreg    = 1;
            end

            i_sll: begin 
                alu     = b << sa;
                wreg    = 1;
            end

            i_srl: begin 
                alu     = b >> sa;
                wreg    = 1;
            end

            i_sra: begin 
                alu     = $signed(b) >>> sa;
                wreg    = 1;
            end

            i_jr: begin 
                next_pc = a;
            end

            i_addi: begin 
                alu     = a + {{16{sign}},imm};
                dest_rn = rt;
                wreg    = 1;
            end

            i_andi: begin
                alu     = a & {16'h0,imm};
                dest_rn = rt;
                wreg    = 1;
            end

            i_ori: begin 
                alu     = a | {16'h0,imm};
                dest_rn = rt;
                wreg    = 1;
            end

            i_xori: begin 
                alu     = a ^ {16'h0,imm};
                dest_rn = rt;
                wreg    = 1;
            end

            i_lw: begin 
                alu     = a + {{16{sign}},imm};
                dest_rn = rt;
                wreg    = 1;
            end

            i_sw: begin
                alu     = a + {{16{sign}},imm};
                dest_rn = rt;
                wmem    = 1;
                wreg    = 1;
            end
    
            i_beq: begin 
                if (a == b) begin 
                    next_pc = pc4 + offset;
                end
            end

            i_bne: begin 
                if (a != b) begin 
                    next_pc = pc4 + offset;
                end
            end

            i_lui: begin 
                alu     = {imm,16'h0};
                wreg    = 1;
            end

            i_j: begin 
                next_pc = j_addr;
            end

            i_jal: begin 
                alu     = pc4;
                wreg    = 1;
                dest_rn = 5'd31;
                next_pc = j_addr;
            end
            default: ;
        endcase
    end
endmodule