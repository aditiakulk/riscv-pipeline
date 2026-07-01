`timescale 1ns/1ps
module tb_branch_debug;
    logic clk, rst;
    cpu_top dut (.clk(clk), .rst(rst));
    always begin clk = 0; #5; clk = 1; #5; end
    integer cycle;
    initial cycle = 0;
    always @(posedge clk) cycle = cycle + 1;

    always @(negedge clk) begin
        if (cycle > 2 && cycle < 30)
            $display("cyc=%0d PC=%0d | ex_br=%b ex_zero=%b mem_br=%b mem_zero=%b bt=%b btgt=%0d | x3=%0d",
                cycle, dut.pc_current,
                dut.ex_branch, dut.ex_zero,
                dut.mem_branch, dut.mem_zero,
                dut.branch_taken, dut.branch_target,
                dut.regfile_inst.registers[3]);
    end

    initial begin
        rst = 1; @(posedge clk); @(posedge clk); rst = 0;
        repeat(30) @(posedge clk);
        $finish;
    end
endmodule
