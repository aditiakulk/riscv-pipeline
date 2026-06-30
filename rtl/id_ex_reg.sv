// id_ex_reg.sv
// Pipeline register between Decode and Execute/Memory stages.
//
// This one carries more than IF/ID because by this point the instruction
// has been fully decoded -- we now have register values, the immediate,
// and every control signal. All of it needs to survive into EX.
//
// rs1_addr/rs2_addr/rd_addr are carried through too, even though EX
// doesn't strictly need rs1_addr/rs2_addr for its own math -- they're
// needed downstream for forwarding (week 5), so we pass them along now
// rather than re-plumbing this register later.

module id_ex_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic         flush,     // clear to NOP (branch misprediction, week 6)

    // Data values
    input  logic [31:0] pc_in,
    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rs1_addr_in,
    input  logic [4:0]  rs2_addr_in,
    input  logic [4:0]  rd_addr_in,

    // Control signals (from decoder)
    input  logic [2:0]  alu_ctrl_in,
    input  logic        alu_src_in,
    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        branch_in,

    output logic [31:0] pc_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rs1_addr_out,
    output logic [4:0]  rs2_addr_out,
    output logic [4:0]  rd_addr_out,

    output logic [2:0]  alu_ctrl_out,
    output logic        alu_src_out,
    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        branch_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            // Zeroing reg_write/mem_read/mem_write/branch is what actually
            // makes this a "do nothing" bubble -- the data fields don't
            // matter if no control signal says to act on them.
            pc_out        <= 32'b0;
            rs1_data_out  <= 32'b0;
            rs2_data_out  <= 32'b0;
            imm_out       <= 32'b0;
            rs1_addr_out  <= 5'b0;
            rs2_addr_out  <= 5'b0;
            rd_addr_out   <= 5'b0;
            alu_ctrl_out  <= 3'b0;
            alu_src_out   <= 1'b0;
            reg_write_out <= 1'b0;
            mem_read_out  <= 1'b0;
            mem_write_out <= 1'b0;
            branch_out    <= 1'b0;
        end else begin
            pc_out        <= pc_in;
            rs1_data_out  <= rs1_data_in;
            rs2_data_out  <= rs2_data_in;
            imm_out       <= imm_in;
            rs1_addr_out  <= rs1_addr_in;
            rs2_addr_out  <= rs2_addr_in;
            rd_addr_out   <= rd_addr_in;
            alu_ctrl_out  <= alu_ctrl_in;
            alu_src_out   <= alu_src_in;
            reg_write_out <= reg_write_in;
            mem_read_out  <= mem_read_in;
            mem_write_out <= mem_write_in;
            branch_out    <= branch_in;
        end
    end

endmodule
