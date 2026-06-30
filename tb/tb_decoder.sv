// tb_decoder.sv
// Tests that each instruction type decodes to the correct fields and
// control signals. Uses the same instructions from imem.sv's test
// program so you can cross-reference.

`timescale 1ns/1ps

module tb_decoder;

    logic [31:0] instr;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] imm;
    logic [2:0]  alu_ctrl;
    logic        alu_src, reg_write, mem_read, mem_write, branch;

    decoder dut (
        .instr(instr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .imm(imm),
        .alu_ctrl(alu_ctrl),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch)
    );

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, tb_decoder);

        // ADDI x1, x0, 5  (0x00500093)
        // I-type: rd=x1, rs1=x0, imm=5
        instr = 32'h00500093; #1;
        if (rd_addr == 5'd1 && rs1_addr == 5'd0 && imm == 32'd5 &&
            reg_write == 1'b1 && alu_src == 1'b1)
            $display("PASS: ADDI x1,x0,5 decoded correctly");
        else
            $display("FAIL: ADDI x1,x0,5 -- rd=%0d rs1=%0d imm=%0d rw=%0d src=%0d",
                      rd_addr, rs1_addr, imm, reg_write, alu_src);

        // ADD x3, x1, x2  (0x002081B3)
        // R-type: rd=x3, rs1=x1, rs2=x2, funct7=0 -> ALU_ADD
        instr = 32'h002081B3; #1;
        if (rd_addr == 5'd3 && rs1_addr == 5'd1 && rs2_addr == 5'd2 &&
            reg_write == 1'b1 && alu_src == 1'b0 && alu_ctrl == 3'b000)
            $display("PASS: ADD x3,x1,x2 decoded correctly");
        else
            $display("FAIL: ADD x3,x1,x2 -- rd=%0d rs1=%0d rs2=%0d alu_ctrl=%0d",
                      rd_addr, rs1_addr, rs2_addr, alu_ctrl);

        // SUB x5, x4, x1  (0x401202B3)
        // R-type: funct7[5]=1 -> ALU_SUB
        instr = 32'h401202B3; #1;
        if (rd_addr == 5'd5 && rs1_addr == 5'd4 && rs2_addr == 5'd1 &&
            alu_ctrl == 3'b001)
            $display("PASS: SUB x5,x4,x1 decoded correctly (alu_ctrl=SUB)");
        else
            $display("FAIL: SUB x5,x4,x1 -- rd=%0d rs1=%0d rs2=%0d alu_ctrl=%0d",
                      rd_addr, rs1_addr, rs2_addr, alu_ctrl);

        // Test a manually constructed SW instruction:
        // SW x2, 8(x1)  -- store x2 into memory at address x1+8
        // S-type encoding: imm[11:5]=0, rs2=x2, rs1=x1, funct3=010, imm[4:0]=8, opcode=0100011
        instr = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'd8, 7'b0100011}; #1;
        if (rs1_addr == 5'd1 && rs2_addr == 5'd2 && imm == 32'd8 &&
            mem_write == 1'b1 && reg_write == 1'b0)
            $display("PASS: SW x2,8(x1) decoded correctly (imm=%0d)", imm);
        else
            $display("FAIL: SW x2,8(x1) -- rs1=%0d rs2=%0d imm=%0d mw=%0d rw=%0d",
                      rs1_addr, rs2_addr, imm, mem_write, reg_write);

        // Test a manually constructed LW instruction:
        // LW x6, 4(x1) -- load from memory at address x1+4 into x6
        instr = {12'd4, 5'd1, 3'b010, 5'd6, 7'b0000011}; #1;
        if (rs1_addr == 5'd1 && rd_addr == 5'd6 && imm == 32'd4 &&
            mem_read == 1'b1 && reg_write == 1'b1)
            $display("PASS: LW x6,4(x1) decoded correctly");
        else
            $display("FAIL: LW x6,4(x1) -- rs1=%0d rd=%0d imm=%0d mr=%0d rw=%0d",
                      rs1_addr, rd_addr, imm, mem_read, reg_write);

        // Test negative immediate sign-extension:
        // ADDI x7, x1, -1  -- imm field = 0xFFF (12 bits, all 1s = -1)
        instr = {12'hFFF, 5'd1, 3'b000, 5'd7, 7'b0010011}; #1;
        if (imm == 32'hFFFFFFFF)
            $display("PASS: negative immediate sign-extended correctly (-1)");
        else
            $display("FAIL: expected imm=0xFFFFFFFF, got 0x%08h", imm);

        $finish;
    end

endmodule
