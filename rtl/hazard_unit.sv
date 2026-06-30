// hazard_unit.sv
// Detects load-use hazards and generates stall signals.
//
// A load-use hazard happens when:
//   LW  x1, 0(x2)     <- in EX stage, mem_read=1, rd=x1
//   ADD x3, x1, x4    <- in ID stage, needs x1
//
// Forwarding can't fix this because LW's result isn't available
// until the END of MEM stage, but the next instruction needs it
// at the START of EX stage -- one cycle too early.
//
// The fix: insert one bubble (NOP) between them by:
//   1. Stalling the PC (don't fetch a new instruction)
//   2. Stalling the IF/ID register (hold the instruction in ID)
//   3. Flushing the ID/EX register (insert a bubble into EX)
//
// After one stall cycle, the LW result will be available via
// normal MEM/WB forwarding and execution continues correctly.

module hazard_unit (
    // The instruction currently in EX -- if it's a LW, it might cause a hazard
    input  logic [4:0] ex_rd_addr,
    input  logic       ex_mem_read,    // 1 = this is a LW instruction

    // Source register addresses of instruction currently in ID
    // (the one that might need the LW result)
    input  logic [4:0] id_rs1_addr,
    input  logic [4:0] id_rs2_addr,

    output logic       stall,          // 1 = freeze PC and IF/ID register
    output logic       id_ex_flush     // 1 = insert bubble into ID/EX register
);

    always_comb begin
        // A load-use hazard exists when:
        // - The instruction in EX is a load (mem_read=1)
        // - Its destination register matches either source of the ID instruction
        if (ex_mem_read &&
            (ex_rd_addr == id_rs1_addr || ex_rd_addr == id_rs2_addr)) begin
            stall      = 1'b1;
            id_ex_flush = 1'b1;
        end else begin
            stall      = 1'b0;
            id_ex_flush = 1'b0;
        end
    end

endmodule
