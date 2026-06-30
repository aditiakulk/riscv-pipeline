// regfile.sv
// 32 registers, 32 bits each. Two combinational read ports (rs1, rs2),
// one synchronous write port (rd). Register 0 is hardwired to zero,
// matching the RISC-V spec -- this matters for your testbench later,
// since x0 should never change no matter what you write to it.

module regfile (
    input  logic        clk,
    input  logic        we,           // write enable
    input  logic [4:0]  rs1_addr,     // source register 1 address
    input  logic [4:0]  rs2_addr,     // source register 2 address
    input  logic [4:0]  rd_addr,      // destination register address
    input  logic [31:0] rd_data,      // data to write into rd
    output logic [31:0] rs1_data,     // value read from rs1
    output logic [31:0] rs2_data      // value read from rs2
);

    logic [31:0] registers [31:0];

    // Reads are combinational -- in real pipelined CPUs, register reads
    // happen in the same cycle as decode, so there's no clock edge here.
    // x0 is hardwired to 0 regardless of what's stored.
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

    // Write is synchronous (on clock edge), and only happens if we=1
    // and we're not trying to write to x0.
    always_ff @(posedge clk) begin
        if (we && rd_addr != 5'b0) begin
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
