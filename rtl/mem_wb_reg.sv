// mem_wb_reg.sv
// Pipeline register between Memory and Writeback stages.
//
// The last one. By now we have two candidate values that might get
// written back to the register file: the ALU result (for ADD/SUB/ADDI)
// or the value just read from data memory (for LW). Both get carried
// forward here -- the actual choice between them happens in the
// Writeback stage itself via a mux, since that's conceptually part of
// "writing back," not part of memory access.

module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] alu_result_in,
    input  logic [31:0] mem_data_in,    // value read from data memory (LW)
    input  logic [4:0]  rd_addr_in,
    input  logic        reg_write_in,
    input  logic        mem_to_reg_in,  // 1 = writeback mem_data, 0 = writeback alu_result

    output logic [31:0] alu_result_out,
    output logic [31:0] mem_data_out,
    output logic [4:0]  rd_addr_out,
    output logic        reg_write_out,
    output logic        mem_to_reg_out
);

    always_ff @(posedge clk) begin
        if (rst) begin
            alu_result_out <= 32'b0;
            mem_data_out   <= 32'b0;
            rd_addr_out    <= 5'b0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule
