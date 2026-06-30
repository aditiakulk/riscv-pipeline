// tb_imem.sv
// Tests that instruction memory returns the right instruction for each PC.
// Key things to verify:
// 1. Correct instruction at each address
// 2. PC byte addressing works (PC=0 -> mem[0], PC=4 -> mem[1], etc.)
// 3. Uninitialized slots return NOP, not garbage

`timescale 1ns/1ps

module tb_imem;

    logic [31:0] pc;
    logic [31:0] instr;

    imem dut (
        .pc(pc),
        .instr(instr)
    );

    initial begin
        $dumpfile("imem.vcd");
        $dumpvars(0, tb_imem);

        // PC=0: should be ADDI x1, x0, 5  (0x00500093)
        pc = 32'd0; #1;
        if (instr == 32'h00500093)
            $display("PASS: PC=0 returns correct instruction 0x%08h", instr);
        else
            $display("FAIL: PC=0 expected 0x00500093, got 0x%08h", instr);

        // PC=4: should be ADDI x2, x0, 3  (0x00300113)
        pc = 32'd4; #1;
        if (instr == 32'h00300113)
            $display("PASS: PC=4 returns correct instruction 0x%08h", instr);
        else
            $display("FAIL: PC=4 expected 0x00300113, got 0x%08h", instr);

        // PC=8: should be ADD x3, x1, x2  (0x002081B3)
        pc = 32'd8; #1;
        if (instr == 32'h002081B3)
            $display("PASS: PC=8 returns correct instruction 0x%08h", instr);
        else
            $display("FAIL: PC=8 expected 0x002081B3, got 0x%08h", instr);

        // PC=12: should be ADDI x4, x3, 10  (0x00A18213)
        pc = 32'd12; #1;
        if (instr == 32'h00A18213)
            $display("PASS: PC=12 returns correct instruction 0x%08h", instr);
        else
            $display("FAIL: PC=12 expected 0x00A18213, got 0x%08h", instr);

        // PC=16: should be SUB x5, x4, x1  (0x401202B3)
        pc = 32'd16; #1;
        if (instr == 32'h401202B3)
            $display("PASS: PC=16 returns correct instruction 0x%08h", instr);
        else
            $display("FAIL: PC=16 expected 0x401202B3, got 0x%08h", instr);

        // PC=20: should be NOP (uninitialized slot -- 0x00000013)
        pc = 32'd20; #1;
        if (instr == 32'h00000013)
            $display("PASS: PC=20 returns NOP for uninitialized slot");
        else
            $display("FAIL: PC=20 expected NOP 0x00000013, got 0x%08h", instr);

        $finish;
    end

endmodule
