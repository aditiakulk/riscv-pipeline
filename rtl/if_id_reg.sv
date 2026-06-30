// if_id_reg.sv
// Pipeline register between Fetch and Decode/Execute stages.
//
// On every clock edge, this captures whatever Fetch produced this cycle
// and holds it steady for Decode to read next cycle. This is what makes
// Fetch and Decode able to work on DIFFERENT instructions simultaneously --
// without this register, there'd be no pipelining, just one big
// combinational block.
//
// "flush" support is included now even though we don't use it until the
// branch-hazard step (week 6) -- when a branch is taken, we'll need to
// wipe out the instruction sitting in this register because it was
// fetched from the wrong path.

module if_id_reg (
    input  logic        clk,
    input  logic        rst,        // synchronous reset (clears to NOP state)
    input  logic        stall,      // 1 = hold current contents (for load-use hazard, week 5)
    input  logic        flush,      // 1 = clear to NOP (for branch misprediction, week 6)

    input  logic [31:0] instr_in,
    input  logic [31:0] pc_in,

    output logic [31:0] instr_out,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            // NOP encoding: all zeros decodes to opcode 0000000, which
            // your decoder's "default" case already treats as a no-op
            // (reg_write etc. all stay 0). Convenient -- no special NOP
            // instruction needed.
            instr_out <= 32'b0;
            pc_out    <= 32'b0;
        end else if (stall) begin
            // Hold current values -- don't advance. Used when a load-use
            // hazard means Decode needs to wait a cycle.
            instr_out <= instr_out;
            pc_out    <= pc_out;
        end else begin
            instr_out <= instr_in;
            pc_out    <= pc_in;
        end
    end

endmodule
