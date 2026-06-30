// tb_if_id_reg.sv
`timescale 1ns/1ps

module tb_if_id_reg;

    logic        clk, rst, stall, flush;
    logic [31:0] instr_in, pc_in;
    logic [31:0] instr_out, pc_out;

    if_id_reg dut (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .instr_in(instr_in), .pc_in(pc_in),
        .instr_out(instr_out), .pc_out(pc_out)
    );

    always begin
        clk = 0; #5;
        clk = 1; #5;
    end

    initial begin
        $dumpfile("if_id_reg.vcd");
        $dumpvars(0, tb_if_id_reg);

        // Reset first
        rst = 1; stall = 0; flush = 0; instr_in = 0; pc_in = 0;
        @(posedge clk); #1;
        if (instr_out == 0 && pc_out == 0)
            $display("PASS: reset clears register to zero");
        else
            $display("FAIL: reset did not clear register");
        rst = 0;

        // Normal pass-through: value should appear AFTER the clock edge,
        // not immediately (that's the whole point of a pipeline register)
        instr_in = 32'h00500093; pc_in = 32'h00000000;
        @(posedge clk); #1;
        if (instr_out == 32'h00500093 && pc_out == 32'h00000000)
            $display("PASS: instruction latched correctly on clock edge");
        else
            $display("FAIL: expected instr_out=0x500093, got %h", instr_out);

        // Stall: next-cycle inputs change, but output should NOT change
        instr_in = 32'hDEADBEEF; pc_in = 32'h00000004;
        stall = 1;
        @(posedge clk); #1;
        if (instr_out == 32'h00500093)
            $display("PASS: stall correctly held previous value");
        else
            $display("FAIL: stall did not hold value, got %h", instr_out);
        stall = 0;

        // Now let the new value flow through normally
        @(posedge clk); #1;
        if (instr_out == 32'hDEADBEEF && pc_out == 32'h00000004)
            $display("PASS: after stall released, new value latches correctly");
        else
            $display("FAIL: expected DEADBEEF, got %h", instr_out);

        // Flush: should clear to zero regardless of inputs
        instr_in = 32'hCAFEF00D; pc_in = 32'h00000008;
        flush = 1;
        @(posedge clk); #1;
        if (instr_out == 32'b0 && pc_out == 32'b0)
            $display("PASS: flush correctly clears to NOP");
        else
            $display("FAIL: flush did not clear, got %h", instr_out);

        $finish;
    end

endmodule
