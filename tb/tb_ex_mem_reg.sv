// tb_ex_mem_reg.sv
`timescale 1ns/1ps

module tb_ex_mem_reg;

    logic clk, rst;
    logic [31:0] alu_result_in, rs2_data_in;
    logic [4:0]  rd_addr_in;
    logic        zero_flag_in, reg_write_in, mem_read_in, mem_write_in, branch_in;

    logic [31:0] alu_result_out, rs2_data_out;
    logic [4:0]  rd_addr_out;
    logic        zero_flag_out, reg_write_out, mem_read_out, mem_write_out, branch_out;

    ex_mem_reg dut (.*);

    always begin clk = 0; #5; clk = 1; #5; end

    initial begin
        $dumpfile("ex_mem_reg.vcd");
        $dumpvars(0, tb_ex_mem_reg);

        rst = 1;
        alu_result_in = 0; rs2_data_in = 0; rd_addr_in = 0; zero_flag_in = 0;
        reg_write_in = 0; mem_read_in = 0; mem_write_in = 0; branch_in = 0;
        @(posedge clk); #1;
        if (alu_result_out == 0 && reg_write_out == 0)
            $display("PASS: reset clears register");
        else
            $display("FAIL: reset did not clear");
        rst = 0;

        // Simulate SW x2, 8(x1): ALU computed address=108, storing rs2_data=99
        alu_result_in = 108; rs2_data_in = 99; rd_addr_in = 0; zero_flag_in = 0;
        reg_write_in = 0; mem_read_in = 0; mem_write_in = 1; branch_in = 0;
        @(posedge clk); #1;
        if (alu_result_out == 108 && rs2_data_out == 99 && mem_write_out == 1)
            $display("PASS: SW fields latched correctly (addr=108, data=99)");
        else
            $display("FAIL: SW fields incorrect");

        // Simulate BEQ where rs1==rs2: zero_flag should be 1
        alu_result_in = 0; zero_flag_in = 1; branch_in = 1;
        mem_write_in = 0;
        @(posedge clk); #1;
        if (zero_flag_out == 1 && branch_out == 1)
            $display("PASS: branch zero_flag latched correctly");
        else
            $display("FAIL: branch fields incorrect");

        $finish;
    end

endmodule
