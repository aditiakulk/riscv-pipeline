// mem_wb_reg.sv
// Pipeline register between Memory and Writeback stages.
// Added flush support to clear on branch misprediction.

module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,         // NEW: clear on branch taken

    input  logic [31:0] alu_result_in,
    input  logic [31:0] mem_data_in,
    input  logic [4:0]  rd_addr_in,
    input  logic        reg_write_in,
    input  logic        mem_to_reg_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] mem_data_out,
    output logic [4:0]  rd_addr_out,
    output logic        reg_write_out,
    output logic        mem_to_reg_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
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
