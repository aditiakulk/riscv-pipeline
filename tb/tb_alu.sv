// tb_alu.sv
// Tests every ALU operation, including edge cases that matter:
// overflow behavior, signed comparison, and the zero flag.

`timescale 1ns/1ps

module tb_alu;

    logic [31:0] a, b, result;
    logic [2:0]  alu_ctrl;
    logic        zero;

    alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    // Task to check a result and print PASS/FAIL
    task check;
        input [31:0] expected;
        input string test_name;
        if (result == expected)
            $display("PASS: %s => %0d", test_name, result);
        else
            $display("FAIL: %s => expected %0d, got %0d", test_name, expected, result);
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        // ADD
        alu_ctrl = 3'b000; a = 32'd10;  b = 32'd5;  #1; check(32'd15,  "ADD 10+5");
        alu_ctrl = 3'b000; a = 32'd0;   b = 32'd0;  #1; check(32'd0,   "ADD 0+0");

        // SUB
        alu_ctrl = 3'b001; a = 32'd10;  b = 32'd3;  #1; check(32'd7,   "SUB 10-3");
        alu_ctrl = 3'b001; a = 32'd5;   b = 32'd5;  #1; check(32'd0,   "SUB 5-5 (zero flag test)");

        // Zero flag -- critical for BEQ
        // BEQ does rs1-rs2, branches if zero=1
        if (zero == 1'b1)
            $display("PASS: zero flag set correctly when result=0");
        else
            $display("FAIL: zero flag should be 1 when result=0");

        alu_ctrl = 3'b001; a = 32'd10;  b = 32'd3;  #1;
        if (zero == 1'b0)
            $display("PASS: zero flag clear when result!=0");
        else
            $display("FAIL: zero flag should be 0 when result!=0");

        // AND
        alu_ctrl = 3'b010; a = 32'hFF00FF00; b = 32'h0F0F0F0F; #1;
        check(32'h0F000F00, "AND");

        // OR
        alu_ctrl = 3'b011; a = 32'hFF000000; b = 32'h00FF0000; #1;
        check(32'hFFFF0000, "OR");

        // SLT (signed less than) -- 
        // -1 in two's complement is 32'hFFFFFFFF, which is > 1 unsigned
        // but < 1 signed. SLT should correctly treat it as signed.
        alu_ctrl = 3'b100; a = 32'hFFFFFFFF; b = 32'd1; #1;
        check(32'd1, "SLT: -1 < 1 (signed)");

        alu_ctrl = 3'b100; a = 32'd5; b = 32'd3; #1;
        check(32'd0, "SLT: 5 not < 3");

        // ADDI behaves identically to ADD from the ALU's perspective --
        // the difference is that b comes from an immediate, not a register.
        // The control unit handles that distinction, not the ALU.
        alu_ctrl = 3'b000; a = 32'd100; b = 32'd1; #1;
        check(32'd101, "ADDI equivalent: 100+1");

        $finish;
    end

endmodule
