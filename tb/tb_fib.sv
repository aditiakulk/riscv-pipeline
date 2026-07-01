// tb_fib.sv
// Fibonacci integration testbench.
//
// Runs the full fibonacci program through the complete 5-stage pipeline:
//   - 3 setup instructions (ADDI x1, ADDI x2, ADDI x3)
//   - 8 loop iterations, each with 6 instructions including a branch
//   - 2 branch types: conditional (BEQ x3,x0) and unconditional (BEQ x0,x0)
//
// This testbench exercises:
//   - Forwarding: ADD x4,x1,x2 immediately reads x1/x2 written just before
//   - Branch flushing: 2 wrong-path instructions flushed every loop iteration
//   - Loop counter decrement: ADDI with negative immediate
//   - Full pipeline correctness over many cycles
//
// Expected result: x2 = 34 after the loop completes

`timescale 1ns/1ps

module tb_fib;

    logic clk, rst;

    cpu_top dut (.clk(clk), .rst(rst));

    always begin clk = 0; #5; clk = 1; #5; end

    initial begin
        $dumpfile("fib.vcd");
        $dumpvars(0, tb_fib);

        // Reset for 2 cycles
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Run long enough for the fibonacci program to complete.
        // 3 setup instructions + 8 iterations * 6 instructions = 51 instructions
        // Each branch flushes 2 cycles, 9 branches total = ~18 extra cycles
        // Plus pipeline fill/drain = ~5 cycles each end
        // Total estimate: ~80 cycles. Run 150 to be safe.
        repeat(250) @(posedge clk);

        // Check results
        $display("\n=== Fibonacci Program Results ===");
        $display("x1 = %0d (expected 21 -- second-to-last fib value)",
            dut.regfile_inst.registers[1]);
        $display("x2 = %0d (expected 34 -- final fib value)",
            dut.regfile_inst.registers[2]);
        $display("x3 = %0d (expected 0  -- loop counter exhausted)",
            dut.regfile_inst.registers[3]);
        $display("x4 = %0d (expected 34 -- last computed sum)",
            dut.regfile_inst.registers[4]);

        if (dut.regfile_inst.registers[2] == 32'd34)
            $display("\nPASS: x2=34 -- fibonacci program executed correctly!");
        else
            $display("\nFAIL: x2=%0d, expected 34",
                dut.regfile_inst.registers[2]);

        if (dut.regfile_inst.registers[3] == 32'd0)
            $display("PASS: x3=0  -- loop counter correctly reached zero");
        else
            $display("FAIL: x3=%0d, expected 0",
                dut.regfile_inst.registers[3]);

        if (dut.regfile_inst.registers[1] == 32'd21)
            $display("PASS: x1=21 -- second-to-last fibonacci value correct");
        else
            $display("FAIL: x1=%0d, expected 21",
                dut.regfile_inst.registers[1]);

        $display("\n=== Pipeline Health Check ===");
        $display("If all three PASS: forwarding, hazard detection,");
        $display("branch flushing, and loop control all work correctly.\n");

        $finish;
    end

endmodule
