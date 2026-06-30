// tb_hazard_unit.sv
`timescale 1ns/1ps

module tb_hazard_unit;

    logic [4:0] ex_rd_addr, id_rs1_addr, id_rs2_addr;
    logic       ex_mem_read;
    logic       stall, id_ex_flush;

    hazard_unit dut (.*);

    initial begin
        // Test 1: No hazard -- LW but different registers
        ex_rd_addr = 1; ex_mem_read = 1;
        id_rs1_addr = 2; id_rs2_addr = 3;
        #1;
        if (stall == 0 && id_ex_flush == 0)
            $display("PASS: no hazard when registers differ");
        else
            $display("FAIL: spurious stall");

        // Test 2: Load-use hazard on rs1
        // LW x1 in EX, next instruction reads x1 as rs1
        ex_rd_addr = 1; ex_mem_read = 1;
        id_rs1_addr = 1; id_rs2_addr = 3;
        #1;
        if (stall == 1 && id_ex_flush == 1)
            $display("PASS: load-use hazard on rs1 detected correctly");
        else
            $display("FAIL: should stall for load-use rs1");

        // Test 3: Load-use hazard on rs2
        ex_rd_addr = 5; ex_mem_read = 1;
        id_rs1_addr = 2; id_rs2_addr = 5;
        #1;
        if (stall == 1 && id_ex_flush == 1)
            $display("PASS: load-use hazard on rs2 detected correctly");
        else
            $display("FAIL: should stall for load-use rs2");

        // Test 4: Same register addresses but NOT a load (ADD) -- no stall needed
        // Forwarding handles RAW hazards for non-load instructions
        ex_rd_addr = 1; ex_mem_read = 0;
        id_rs1_addr = 1; id_rs2_addr = 2;
        #1;
        if (stall == 0 && id_ex_flush == 0)
            $display("PASS: no stall for non-load hazard (forwarding handles it)");
        else
            $display("FAIL: should not stall for non-load even with same register");

        $finish;
    end

endmodule
