// tb_dmem.sv
// Tests data memory read/write behavior. Key things to verify:
// 1. Writes only happen when we=1, and only on the clock edge
// 2. Reads are combinational -- value available without waiting for clk
// 3. Writing to one address doesn't affect others

`timescale 1ns/1ps

module tb_dmem;

    logic        clk;
    logic        we;
    logic [31:0] addr, write_data, read_data;

    dmem dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always begin
        clk = 0; #5;
        clk = 1; #5;
    end

    initial begin
        $dumpfile("dmem.vcd");
        $dumpvars(0, tb_dmem);

        // Test 1: write 77 to address 0, then read it back
        we = 1; addr = 32'd0; write_data = 32'd77;
        @(posedge clk);
        #1;
        we = 0;
        #1;
        if (read_data == 32'd77)
            $display("PASS: wrote 77 to addr 0, read back %0d", read_data);
        else
            $display("FAIL: expected 77, got %0d", read_data);

        // Test 2: write to a different address, confirm addr 0 unchanged
        we = 1; addr = 32'd4; write_data = 32'd200;
        @(posedge clk);
        #1;
        we = 0; addr = 32'd0;
        #1;
        if (read_data == 32'd77)
            $display("PASS: addr 0 still holds 77 after writing addr 4");
        else
            $display("FAIL: addr 0 corrupted, got %0d", read_data);

        addr = 32'd4;
        #1;
        if (read_data == 32'd200)
            $display("PASS: addr 4 holds 200 correctly");
        else
            $display("FAIL: addr 4 expected 200, got %0d", read_data);

        // Test 3: with we=0, writing shouldn't happen even if write_data changes
        we = 0; addr = 32'd8; write_data = 32'd999;
        @(posedge clk);
        #1;
        if (read_data == 32'd0)
            $display("PASS: addr 8 unwritten (we=0 correctly blocked write)");
        else
            $display("FAIL: addr 8 should be 0, got %0d", read_data);

        $finish;
    end

endmodule
