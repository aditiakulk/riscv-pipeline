// branch_adder.sv
// Computes the branch target address in the EX stage.
// RISC-V branches are PC-relative: the target is the PC of the branch
// instruction itself plus the sign-extended immediate offset.
// This is a purely combinational adder -- no clock needed.
//
// Why a separate module instead of just using the ALU?
// The ALU is already busy computing (rs1 - rs2) to check if rs1==rs2
// for BEQ. We need the branch target simultaneously, so it gets its
// own dedicated adder. In real CPUs this is often called the "branch
// address adder" or "branch target unit."

module branch_adder (
    input  logic [31:0] pc,       // PC of the branch instruction (from ID/EX reg)
    input  logic [31:0] imm,      // sign-extended B-type immediate (from ID/EX reg)
    output logic [31:0] target    // branch target address = pc + imm
);
    assign target = pc + imm;

endmodule
