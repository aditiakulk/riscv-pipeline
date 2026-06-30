// tb_regfile.sv
// Standalone testbench for regfile.sv. The point of testing this in
// isolation (before building anything else) is to confirm your
// toolchain -- compile, simulate, view waveforms -- actually works,
// and that this one module is correct before you build on top of it.

`timescale 1ns/1ps

module tb_regfile;

    logic        clk;
    logic        we;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data, rs2_data;

    // Instantiate the module under test
    regfile dut (
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock generation: toggle every 5ns -> 100MHz-equivalent clock
    always begin
        clk = 0; #5;
        clk = 1; #5;
    end

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, tb_regfile);

        // Test 1: write 42 into x5, then read it back
        we = 1; rd_addr = 5; rd_data = 32'd42;
        @(posedge clk);
        #1; // small delay so we read after the write has settled

        we = 0; rs1_addr = 5;
        #1;
        if (rs1_data == 32'd42)
            $display("PASS: wrote 42 to x5, read back %0d", rs1_data);
        else
            $display("FAIL: expected 42, got %0d", rs1_data);

        // Test 2: x0 should always read as zero, even if we try to write it
        we = 1; rd_addr = 0; rd_data = 32'd999;
        @(posedge clk);
        #1;
        we = 0; rs1_addr = 0;
        #1;
        if (rs1_data == 32'd0)
            $display("PASS: x0 correctly hardwired to zero");
        else
            $display("FAIL: x0 should be 0, got %0d", rs1_data);

        // Test 3: simultaneous read of two different registers
        we = 1; rd_addr = 10; rd_data = 32'd100;
        @(posedge clk); #1;
        we = 1; rd_addr = 11; rd_data = 32'd200;
        @(posedge clk); #1;

        we = 0; rs1_addr = 10; rs2_addr = 11;
        #1;
        if (rs1_data == 32'd100 && rs2_data == 32'd200)
            $display("PASS: dual-port read works, x10=%0d x11=%0d", rs1_data, rs2_data);
        else
            $display("FAIL: dual-port read incorrect");

        $finish;
    end

endmodule
