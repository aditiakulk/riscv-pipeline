// forwarding_unit.sv
// Detects when an instruction in EX needs a value that a previous
// instruction has already computed but not yet written to the register
// file, and selects the correct forwarding path.
//
// Outputs are mux select signals:
//   forward_a: selects what goes into ALU operand A (rs1)
//   forward_b: selects what goes into ALU operand B (rs2, BEFORE the alu_src mux)
//
//   2'b00 = use register file value (no hazard, normal case)
//   2'b10 = forward from EX/MEM stage (instruction 1 cycle ahead)
//   2'b01 = forward from MEM/WB stage (instruction 2 cycles ahead)
//
// Why check reg_write? Because only instructions that actually write
// a register can cause a data hazard. SW and BEQ don't write registers,
// so they can never be the SOURCE of a forwarding situation.
//
// Why check rd != 0? Because x0 is hardwired to zero -- if something
// "writes" x0 (even though it won't stick), we don't want to forward
// that zero and corrupt another instruction's operand.

module forwarding_unit (
    // Register addresses of instruction currently in EX stage
    input  logic [4:0] ex_rs1_addr,
    input  logic [4:0] ex_rs2_addr,

    // Destination register and write-enable of instruction in MEM stage
    input  logic [4:0] mem_rd_addr,
    input  logic       mem_reg_write,

    // Destination register and write-enable of instruction in WB stage
    input  logic [4:0] wb_rd_addr,
    input  logic       wb_reg_write,

    output logic [1:0] forward_a,   // mux select for ALU operand A
    output logic [1:0] forward_b    // mux select for ALU operand B
);

    always_comb begin
        // Default: no forwarding needed
        forward_a = 2'b00;
        forward_b = 2'b00;

        // --- Forwarding for operand A (rs1) ---
        // EX/MEM hazard: instruction in MEM wrote rd that EX needs as rs1
        // Check MEM first -- it's more recent than WB, so it wins if both match
        if (mem_reg_write && mem_rd_addr != 5'b0
            && mem_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b10;   // forward from EX/MEM
        end
        // MEM/WB hazard: instruction in WB wrote rd that EX needs as rs1
        // Only applies if MEM stage isn't already forwarding (MEM takes priority)
        else if (wb_reg_write && wb_rd_addr != 5'b0
            && wb_rd_addr == ex_rs1_addr) begin
            forward_a = 2'b01;   // forward from MEM/WB
        end

        // --- Forwarding for operand B (rs2) ---
        // Same logic, same priority -- MEM over WB
        if (mem_reg_write && mem_rd_addr != 5'b0
            && mem_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b10;
        end
        else if (wb_reg_write && wb_rd_addr != 5'b0
            && wb_rd_addr == ex_rs2_addr) begin
            forward_b = 2'b01;
        end
    end

endmodule
