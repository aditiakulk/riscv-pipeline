// dmem.sv
// Data memory -- used by LW (load word) and SW (store word) instructions.
// Unlike imem (read-only), this memory supports both reads and writes.
//
// Read is combinational (address in, data out same cycle) so the MEM
// stage can use the loaded value immediately. Write is synchronous
// (happens on clock edge), same pattern as the register file write port.

module dmem (
    input  logic        clk,
    input  logic        we,          // write enable (1 for SW, 0 otherwise)
    input  logic [31:0] addr,        // byte address to read/write
    input  logic [31:0] write_data,  // data to store (for SW)
    output logic [31:0] read_data    // data loaded (for LW)
);

    // 64 words of data memory -- plenty for our test programs
    logic [31:0] mem [0:63];

    initial begin
        for (int i = 0; i < 64; i++) begin
            mem[i] = 32'b0;
        end
    end

    // Synchronous write -- happens on the clock edge, same as regfile
    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr[7:2]] <= write_data;
        end
    end

    // Combinational read -- LW needs the value available within the
    // same MEM stage cycle, no waiting for a clock edge
    assign read_data = mem[addr[7:2]];

endmodule
