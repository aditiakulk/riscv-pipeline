// imem.sv
// Instruction memory preloaded with the fibonacci test program.
//
// Program computes fibonacci iteratively:
//   x1=0, x2=1, loop 8 times: x4=x1+x2, x1=x2, x2=x4, x3--
//   BEQ x3,x0 exits loop when counter hits 0
//   BEQ x0,x0 loops back unconditionally
//
// Expected final state: x2 = 34 (8 iterations from fib(0)=0,fib(1)=1)

module imem (
    input  logic [31:0] pc,
    output logic [31:0] instr
);

    logic [31:0] mem [0:63];

    initial begin
        for (int i = 0; i < 64; i++)
            mem[i] = 32'h00000013;  // NOP

        // addr  0: ADDI x1, x0, 0     x1 = 0 (fib[n-2])
        mem[0] = 32'h00000093;
        // addr  4: ADDI x2, x0, 1     x2 = 1 (fib[n-1])
        mem[1] = 32'h00100113;
        // addr  8: ADDI x3, x0, 8     x3 = 8 (loop counter)
        mem[2] = 32'h00800193;
        // addr 12: ADD  x4, x1, x2    x4 = x1 + x2  [LOOP START]
        mem[3] = 32'h00208233;
        // addr 16: ADD  x1, x2, x0    x1 = x2
        mem[4] = 32'h000100B3;
        // addr 20: ADD  x2, x4, x0    x2 = x4
        mem[5] = 32'h00020133;
        // addr 24: ADDI x3, x3, -1    x3--
        mem[6] = 32'hFFF18193;
        // addr 28: BEQ  x3, x0, +8    if x3==0, jump to addr 36 (done)
        mem[7] = 32'h00018463;
        // addr 32: BEQ  x0, x0, -20   unconditional jump back to addr 12
        mem[8] = 32'hFE0006E3;
        // addr 36: NOP -- done, x2 holds the answer
    end

    assign instr = mem[pc[7:2]];

endmodule
