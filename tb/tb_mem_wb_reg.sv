// tb_mem_wb_reg.sv
`timescale 1ns/1ps

module tb_mem_wb_reg;

    logic clk, rst;
    logic [31:0] alu_result_in, mem_data_in;
    logic [4:0]  rd_addr_in;
    logic        reg_write_in, mem_to_reg_in;

    logic [31:0] alu_result_out, mem_data_out;
    logic [4:0]  rd_addr_out;
    logic        reg_write_out, mem_to_reg_out;

    mem_wb_reg dut (.*);

    always begin clk = 0; #5; clk = 1; #5; end

    initial begin
        $dumpfile("mem_wb_reg.vcd");
        $dumpvars(0, tb_mem_wb_reg);

        rst = 1;
        alu_result_in = 0; mem_data_in = 0; rd_addr_in = 0;
        reg_write_in = 0; mem_to_reg_in = 0;
        @(posedge clk); #1;
        if (reg_write_out == 0)
            $display("PASS: reset clears register");
        else
            $display("FAIL: reset did not clear");
        rst = 0;

        // Simulate LW x6, 4(x1): mem_data=55 should be selected for writeback
        alu_result_in = 999; mem_data_in = 55; rd_addr_in = 6;
        reg_write_in = 1; mem_to_reg_in = 1;
        @(posedge clk); #1;
        if (mem_data_out == 55 && mem_to_reg_out == 1 && rd_addr_out == 6)
            $display("PASS: LW fields latched correctly, mem_to_reg=1");
        else
            $display("FAIL: LW fields incorrect");

        // Simulate ADD x3,...: alu_result should be selected (mem_to_reg=0)
        alu_result_in = 42; mem_data_in = 0; rd_addr_in = 3;
        reg_write_in = 1; mem_to_reg_in = 0;
        @(posedge clk); #1;
        if (alu_result_out == 42 && mem_to_reg_out == 0 && rd_addr_out == 3)
            $display("PASS: ADD fields latched correctly, mem_to_reg=0");
        else
            $display("FAIL: ADD fields incorrect");

        $finish;
    end

endmodule
