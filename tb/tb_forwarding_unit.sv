// tb_forwarding_unit.sv
`timescale 1ns/1ps

module tb_forwarding_unit;

    logic [4:0] ex_rs1_addr, ex_rs2_addr;
    logic [4:0] mem_rd_addr, wb_rd_addr;
    logic       mem_reg_write, wb_reg_write;
    logic [1:0] forward_a, forward_b;

    forwarding_unit dut (.*);

    initial begin
        // Test 1: No hazard -- all different registers
        ex_rs1_addr = 1; ex_rs2_addr = 2;
        mem_rd_addr = 3; mem_reg_write = 1;
        wb_rd_addr  = 4; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b00 && forward_b == 2'b00)
            $display("PASS: no hazard, no forwarding");
        else
            $display("FAIL: spurious forwarding fa=%b fb=%b", forward_a, forward_b);

        // Test 2: EX/MEM hazard on rs1 -- MEM has result EX needs
        ex_rs1_addr = 5; ex_rs2_addr = 2;
        mem_rd_addr = 5; mem_reg_write = 1;
        wb_rd_addr  = 9; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b10 && forward_b == 2'b00)
            $display("PASS: EX/MEM hazard on rs1 correctly detected");
        else
            $display("FAIL: expected fa=10 fb=00, got fa=%b fb=%b", forward_a, forward_b);

        // Test 3: MEM/WB hazard on rs2 -- WB has result EX needs
        ex_rs1_addr = 1; ex_rs2_addr = 7;
        mem_rd_addr = 3; mem_reg_write = 1;
        wb_rd_addr  = 7; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b00 && forward_b == 2'b01)
            $display("PASS: MEM/WB hazard on rs2 correctly detected");
        else
            $display("FAIL: expected fa=00 fb=01, got fa=%b fb=%b", forward_a, forward_b);

        // Test 4: Double hazard -- both rs1 and rs2 need forwarding
        ex_rs1_addr = 5; ex_rs2_addr = 7;
        mem_rd_addr = 5; mem_reg_write = 1;
        wb_rd_addr  = 7; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b10 && forward_b == 2'b01)
            $display("PASS: double hazard -- rs1 from MEM, rs2 from WB");
        else
            $display("FAIL: expected fa=10 fb=01, got fa=%b fb=%b", forward_a, forward_b);

        // Test 5: MEM priority over WB when both match rs1
        // (two instructions ahead both wrote the same register -- MEM is newer)
        ex_rs1_addr = 5; ex_rs2_addr = 0;
        mem_rd_addr = 5; mem_reg_write = 1;
        wb_rd_addr  = 5; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b10)
            $display("PASS: MEM takes priority over WB when both match");
        else
            $display("FAIL: MEM should win priority, got fa=%b", forward_a);

        // Test 6: No forwarding if reg_write=0 (e.g. SW in MEM stage)
        ex_rs1_addr = 5; ex_rs2_addr = 2;
        mem_rd_addr = 5; mem_reg_write = 0;   // SW doesn't write a register
        wb_rd_addr  = 9; wb_reg_write  = 0;
        #1;
        if (forward_a == 2'b00 && forward_b == 2'b00)
            $display("PASS: no forwarding when reg_write=0");
        else
            $display("FAIL: should not forward when reg_write=0");

        // Test 7: No forwarding to x0 -- even if rd=0 and rs1=0
        ex_rs1_addr = 0; ex_rs2_addr = 0;
        mem_rd_addr = 0; mem_reg_write = 1;
        wb_rd_addr  = 0; wb_reg_write  = 1;
        #1;
        if (forward_a == 2'b00 && forward_b == 2'b00)
            $display("PASS: x0 never forwarded");
        else
            $display("FAIL: x0 should never trigger forwarding");

        $finish;
    end

endmodule
