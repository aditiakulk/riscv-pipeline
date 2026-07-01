// ex_mem_reg.sv
// Pipeline register between Execute and Memory stages.
// Added flush support to clear on branch misprediction.

module ex_mem_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,         // NEW: clear on branch taken

    input  logic [31:0] alu_result_in,
    input  logic [31:0] rs2_data_in,
    input  logic [4:0]  rd_addr_in,
    input  logic        zero_flag_in,

    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        branch_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] rs2_data_out,
    output logic [4:0]  rd_addr_out,
    output logic        zero_flag_out,

    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        branch_out
);

    always_ff @(posedge clk) begin
        if (rst || flush) begin
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;
            rd_addr_out    <= 5'b0;
            zero_flag_out  <= 1'b0;
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            branch_out     <= 1'b0;
        end else begin
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            rd_addr_out    <= rd_addr_in;
            zero_flag_out  <= zero_flag_in;
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            branch_out     <= branch_in;
        end
    end

endmodule
