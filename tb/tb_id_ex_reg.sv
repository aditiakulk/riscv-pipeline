// tb_id_ex_reg.sv
`timescale 1ns/1ps

module tb_id_ex_reg;

    logic clk, rst, flush;
    logic [31:0] pc_in, rs1_data_in, rs2_data_in, imm_in;
    logic [4:0]  rs1_addr_in, rs2_addr_in, rd_addr_in;
    logic [2:0]  alu_ctrl_in;
    logic        alu_src_in, reg_write_in, mem_read_in, mem_write_in, branch_in;

    logic [31:0] pc_out, rs1_data_out, rs2_data_out, imm_out;
    logic [4:0]  rs1_addr_out, rs2_addr_out, rd_addr_out;
    logic [2:0]  alu_ctrl_out;
    logic        alu_src_out, reg_write_out, mem_read_out, mem_write_out, branch_out;

    id_ex_reg dut (.*);

    always begin clk = 0; #5; clk = 1; #5; end

    initial begin
        $dumpfile("id_ex_reg.vcd");
        $dumpvars(0, tb_id_ex_reg);

        rst = 1; flush = 0;
        pc_in = 0; rs1_data_in = 0; rs2_data_in = 0; imm_in = 0;
        rs1_addr_in = 0; rs2_addr_in = 0; rd_addr_in = 0;
        alu_ctrl_in = 0; alu_src_in = 0; reg_write_in = 0;
        mem_read_in = 0; mem_write_in = 0; branch_in = 0;
        @(posedge clk); #1;
        if (reg_write_out == 0 && rd_addr_out == 0)
            $display("PASS: reset clears register");
        else
            $display("FAIL: reset did not clear");
        rst = 0;

        // Simulate ADD x3, x1, x2 flowing through: rs1=10, rs2=20, rd=3
        pc_in = 32'h4; rs1_data_in = 10; rs2_data_in = 20; imm_in = 0;
        rs1_addr_in = 1; rs2_addr_in = 2; rd_addr_in = 3;
        alu_ctrl_in = 3'b000; alu_src_in = 0; reg_write_in = 1;
        mem_read_in = 0; mem_write_in = 0; branch_in = 0;
        @(posedge clk); #1;

        if (rs1_data_out == 10 && rs2_data_out == 20 && rd_addr_out == 3
            && reg_write_out == 1 && alu_ctrl_out == 3'b000)
            $display("PASS: ADD instruction fields latched correctly");
        else
            $display("FAIL: ADD fields incorrect - rs1=%0d rs2=%0d rd=%0d rw=%0d",
                      rs1_data_out, rs2_data_out, rd_addr_out, reg_write_out);

        // Flush should clear everything to bubble state
        flush = 1;
        @(posedge clk); #1;
        if (reg_write_out == 0 && mem_write_out == 0 && branch_out == 0)
            $display("PASS: flush clears control signals to bubble");
        else
            $display("FAIL: flush did not clear control signals");

        $finish;
    end

endmodule
