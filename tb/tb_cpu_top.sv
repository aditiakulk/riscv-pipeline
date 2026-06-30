// tb_cpu_top.sv
// Full pipeline integration testbench.
//
// This is the moment everything comes together -- instead of testing
// one module at a time, we're running an actual program through the
// complete 5-stage pipeline and checking that the right values end up
// in the right registers.
//
// The test program (already in imem.sv) is:
//   ADDI x1, x0, 5    -- x1 = 5
//   ADDI x2, x0, 3    -- x2 = 3
//   ADD  x3, x1, x2   -- x3 = x1 + x2 = 8
//   ADDI x4, x3, 10   -- x4 = x3 + 10 = 18
//   SUB  x5, x4, x1   -- x5 = x4 - x1 = 13
//
// IMPORTANT: Because this is a pipeline WITHOUT hazard handling yet,
// results WON'T be correct yet -- dependent instructions (ADD x3 needs
// x1 and x2 which aren't written back yet when ADD is in EX) will read
// stale register values. This testbench's primary job right now is to
// confirm the pipeline RUNS without hanging, signals flow correctly,
// and no X (undefined) values propagate. Correctness comes in week 5
// after forwarding is added.

`timescale 1ns/1ps

module tb_cpu_top;

    logic clk, rst;

    cpu_top dut (.clk(clk), .rst(rst));

    always begin
        clk = 0; #5;
        clk = 1; #5;
    end

    // Helper to display the pipeline state each cycle so we can
    // see instructions moving through the stages visually.
    always @(posedge clk) begin
        $display("Cycle %0t | IF: PC=%0d | ID: instr=%h | WB: rd=x%0d we=%b data=%0d",
            $time,
            dut.pc_current,
            dut.id_instr,
            dut.wb_rd_addr,
            dut.wb_reg_write,
            dut.wb_write_data);
    end

    initial begin
        $dumpfile("cpu_top.vcd");
        $dumpvars(0, tb_cpu_top);

        // Reset for 2 cycles -- clears PC and all pipeline registers to 0
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Run for 15 cycles -- enough for the 5 instructions to flow
        // all the way through all 5 stages (each instruction takes 5
        // cycles to complete, and we have 5 instructions, but they
        // overlap in the pipeline so 15 cycles gives us comfortable
        // margin to watch everything)
        repeat(15) @(posedge clk);

        // Check the pipeline ran -- read x1 and x2 directly from regfile.
        // Even without forwarding, ADDI x1 and ADDI x2 are the first two
        // instructions and have no dependencies, so they should be correct.
        $display("\n--- Register File State After 15 Cycles ---");
        $display("x1 = %0d (expected 5  -- ADDI x1,x0,5)",
            dut.regfile_inst.registers[1]);
        $display("x2 = %0d (expected 3  -- ADDI x2,x0,3)",
            dut.regfile_inst.registers[2]);
        $display("x3 = %0d (NOTE: may be wrong without forwarding -- expected 8)",
            dut.regfile_inst.registers[3]);
        $display("x4 = %0d (NOTE: may be wrong without forwarding -- expected 18)",
            dut.regfile_inst.registers[4]);
        $display("x5 = %0d (NOTE: may be wrong without forwarding -- expected 13)",
            dut.regfile_inst.registers[5]);

        // The actual correctness checks -- only x1 and x2 should be
        // reliable without hazard handling
        if (dut.regfile_inst.registers[1] == 32'd5)
            $display("\nPASS: x1=5 correct (no dependency, no hazard)");
        else
            $display("\nFAIL: x1=%0d, expected 5", dut.regfile_inst.registers[1]);

        if (dut.regfile_inst.registers[2] == 32'd3)
            $display("PASS: x2=3 correct (no dependency, no hazard)");
        else
            $display("FAIL: x2=%0d, expected 3", dut.regfile_inst.registers[2]);

        $display("\nPipeline integration: COMPLETE");
        $display("Forwarding + stall logic (week 5) will fix x3/x4/x5.\n");

        $finish;
    end

endmodule
