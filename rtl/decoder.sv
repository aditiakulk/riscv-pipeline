// decoder.sv
// Takes a raw 32-bit instruction and extracts every field the rest of
// the pipeline needs: register addresses, immediate value, and control
// signals that tell EX/MEM/WB what to do with this instruction.
//
// This module is purely combinational -- decoding doesn't involve a
// clock, it's just unpacking bits.

module decoder (
    input  logic [31:0] instr,

    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,
    output logic [31:0] imm,          // sign-extended immediate
    output logic [2:0]  alu_ctrl,     // operation for the ALU
    output logic        alu_src,      // 1 = use immediate as ALU operand b, 0 = use rs2
    output logic        reg_write,    // 1 = this instruction writes a register
    output logic        mem_read,     // 1 = this is a load (LW)
    output logic        mem_write,    // 1 = this is a store (SW)
    output logic        branch        // 1 = this is a branch (BEQ)
);

    // Opcodes for our 6-instruction ISA
    localparam OP_RTYPE  = 7'b0110011;  // ADD, SUB
    localparam OP_ITYPE  = 7'b0010011;  // ADDI
    localparam OP_LOAD   = 7'b0000011;  // LW
    localparam OP_STORE  = 7'b0100011;  // SW
    localparam OP_BRANCH = 7'b1100011;  // BEQ

    // ALU control codes -- must match alu.sv's localparams
    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    // Register fields -- these bit positions are the same across
    // R, I, S, and B formats, which is intentional RISC-V design
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    // Immediate generation -- different for each format.
    // Sign-extension matters: we replicate bit 31 (or whatever the
    // top immediate bit is) to fill the upper bits, so negative
    // immediates work correctly in arithmetic.
    logic sign_bit;
    assign sign_bit = instr[31];

    always_comb begin
        case (opcode)
            OP_ITYPE, OP_LOAD:
                // I-type: imm[11:0] = instr[31:20], sign-extend
                imm = {{20{sign_bit}}, instr[31:20]};

            OP_STORE:
                // S-type: imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
                imm = {{20{sign_bit}}, instr[31:25], instr[11:7]};

            OP_BRANCH:
                // B-type: imm is encoded oddly (bit-scrambled for hardware
                // efficiency in real implementations), but conceptually
                // it's a signed offset. Simplified encoding for our subset:
                imm = {{19{sign_bit}}, sign_bit, instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            default:
                imm = 32'b0;
        endcase
    end

    // Control signal generation
    always_comb begin
        // Safe defaults -- every signal off unless explicitly set below
        alu_ctrl  = ALU_ADD;
        alu_src   = 1'b0;
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        branch    = 1'b0;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;          // operand b = rs2
                alu_ctrl  = (funct7[5]) ? ALU_SUB : ALU_ADD; // funct7 bit distinguishes ADD/SUB
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;          // operand b = immediate
                alu_ctrl  = ALU_ADD;       // ADDI is just ADD with an immediate
            end

            OP_LOAD: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;          // address = rs1 + immediate
                alu_ctrl  = ALU_ADD;
                mem_read  = 1'b1;
            end

            OP_STORE: begin
                alu_src   = 1'b1;          // address = rs1 + immediate
                alu_ctrl  = ALU_ADD;
                mem_write = 1'b1;
                // note: reg_write stays 0 -- stores don't write a register
            end

            OP_BRANCH: begin
                alu_src  = 1'b0;           // compare rs1 vs rs2 directly
                alu_ctrl = ALU_SUB;        // BEQ checks (rs1 - rs2 == 0)
                branch   = 1'b1;
                // note: reg_write stays 0 -- branches don't write a register
            end

            default: begin
                // Unrecognized opcode -- treat as NOP, everything stays at defaults
            end
        endcase
    end

endmodule
