// alu.sv
// The ALU (Arithmetic Logic Unit) performs all computation in the CPU.
// It's purely combinational -- no clock, inputs in -> result out immediately.
// The control unit (built later) will tell it which operation to perform
// via alu_ctrl. For now we support the operations our 6-instruction ISA needs.

module alu (
    input  logic [31:0] a,          // first operand (always from rs1)
    input  logic [31:0] b,          // second operand (rs2 or immediate)
    input  logic [2:0]  alu_ctrl,   // which operation to perform
    output logic [31:0] result,     // computed result
    output logic        zero        // 1 if result == 0, used by BEQ
);

    // ALU operation encoding -- we'll use these same codes in the
    // control unit later when decoding instructions
    localparam ALU_ADD  = 3'b000;   // ADD, ADDI, LW, SW (address calc)
    localparam ALU_SUB  = 3'b001;   // SUB
    localparam ALU_AND  = 3'b010;   // AND (useful later, cheap to add now)
    localparam ALU_OR   = 3'b011;   // OR  (same)
    localparam ALU_SLT  = 3'b100;   // Set Less Than (needed for some branches)

    always_comb begin
        case (alu_ctrl)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default:  result = 32'b0;
        endcase
    end

    // Zero flag -- BEQ works by subtracting rs1-rs2 and checking if result==0
    assign zero = (result == 32'b0);

endmodule
