// tb_pc_reg.sv
`timescale 1ns/1ps

module tb_pc_reg;

    logic        clk, rst, stall, branch_taken;
    logic [31:0] branch_target;
    logic [31:0] pc;

    pc_reg dut (.*);

    always begin clk = 0; #5; clk = 1; #5; end

    initial begin
        rst = 1; stall = 0; branch_taken = 0; branch_target = 0;
        @(posedge clk); #1;
        if (pc == 0)
            $display("PASS: reset sets PC to 0");
        else
            $display("FAIL: PC should be 0 after reset, got %0d", pc);
        rst = 0;

        @(posedge clk); #1;
        if (pc == 4)
            $display("PASS: PC advances by 4 each cycle");
        else
            $display("FAIL: expected PC=4, got %0d", pc);

        @(posedge clk); #1;
        if (pc == 8)
            $display("PASS: PC continues advancing correctly");
        else
            $display("FAIL: expected PC=8, got %0d", pc);

        // Stall should hold PC steady
        stall = 1;
        @(posedge clk); #1;
        if (pc == 8)
            $display("PASS: stall holds PC steady");
        else
            $display("FAIL: PC should stay 8 during stall, got %0d", pc);
        stall = 0;

        // Branch taken should jump to target
        branch_taken = 1; branch_target = 32'd100;
        @(posedge clk); #1;
        if (pc == 100)
            $display("PASS: branch correctly jumps PC to target");
        else
            $display("FAIL: expected PC=100, got %0d", pc);

        $finish;
    end

endmodule
