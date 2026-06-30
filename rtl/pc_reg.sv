// pc_reg.sv
// The Program Counter. Holds the address of the instruction currently
// being fetched. Every cycle it advances -- normally by 4 (since each
// instruction is 4 bytes), but on a taken branch it jumps to the branch
// target instead.
//
// This is intentionally a separate tiny module rather than folding it
// into cpu_top directly -- keeping PC logic isolated makes it easy to
// test on its own and easy to find later when we add branch handling
// in week 6.

module pc_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,        // hold PC steady (load-use hazard, week 5)
    input  logic        branch_taken, // 1 = jump to branch_target instead of pc+4
    input  logic [31:0] branch_target,

    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'b0;
        end else if (stall) begin
            pc <= pc;                  // don't advance -- decode needs another cycle
        end else if (branch_taken) begin
            pc <= branch_target;
        end else begin
            pc <= pc + 32'd4;
        end
    end

endmodule
