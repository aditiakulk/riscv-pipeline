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

    // All field extraction is done here, once, as plain continuous
    // assignments. This avoids constant part-selects appearing inside
    // always_comb blocks, which is what Icarus warns about -- pulling
    // these out into named wires sidesteps the issue entirely and
    // also makes the rest of the module easier to read.
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic        funct7_bit5;   // distinguishes ADD (0) vs SUB (1)
    logic        sign_bit;

    // I-type immediate field: instr[31:20]
    logic [11:0] itype_imm_raw;
    // S-type immediate fields: instr[31:25] and instr[11:7]
    logic [6:0]  stype_imm_hi;
    logic [4:0]  stype_imm_lo;
    // B-type immediate fields: instr[7], instr[30:25], instr[11:8]
    logic        btype_imm_b11;
    logic [5:0]  btype_imm_hi;
    logic [3:0]  btype_imm_lo;

    assign opcode      = instr[6:0];
    assign funct3      = instr[14:12];
    assign funct7_bit5 = instr[30];
    assign sign_bit    = instr[31];

    assign itype_imm_raw = instr[31:20];
    assign stype_imm_hi  = instr[31:25];
    assign stype_imm_lo  = instr[11:7];
    assign btype_imm_b11 = instr[7];
    assign btype_imm_hi  = instr[30:25];
    assign btype_imm_lo  = instr[11:8];

    // Register fields -- these bit positions are the same across
    // R, I, S, and B formats, which is intentional RISC-V design
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    // Immediate generation -- different for each format.
    // Sign-extension matters: we replicate the sign bit to fill the
    // upper bits, so negative immediates work correctly in arithmetic.
    always_comb begin
        case (opcode)
            OP_ITYPE, OP_LOAD:
                imm = {{20{sign_bit}}, itype_imm_raw};

            OP_STORE:
                imm = {{20{sign_bit}}, stype_imm_hi, stype_imm_lo};

            OP_BRANCH:
                // B-type: imm is bit-scrambled for hardware efficiency in
                // real implementations. Simplified encoding for our subset:
                imm = {{19{sign_bit}}, sign_bit, btype_imm_b11,
                       btype_imm_hi, btype_imm_lo, 1'b0};

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
                alu_ctrl  = funct7_bit5 ? ALU_SUB : ALU_ADD; // funct7 bit distinguishes ADD/SUB
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
