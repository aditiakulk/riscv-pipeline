// imem.sv
// Instruction memory -- a read-only array of 32-bit RISC-V instructions.
// The fetch stage sends it a PC (program counter) address and gets back
// the instruction at that address, combinationally (no clock needed).
//
// In a real CPU this would be an actual SRAM or cache. For our purposes
// it's a simple array preloaded with a test program. We'll swap in the
// fibonacci program once the full pipeline is wired up.
//
// RISC-V uses byte addressing but instructions are 4 bytes wide, so
// PC increments by 4 each cycle. We divide by 4 to get the array index.

module imem (
    input  logic [31:0] pc,       // current program counter (byte address)
    output logic [31:0] instr     // instruction at that address
);

    // 64 instructions of storage -- plenty for our test programs
    logic [31:0] mem [0:63];

    // Load the instruction memory with a small test program at startup.
    // This is a RISC-V assembly program that computes fibonacci numbers.
    //
    // Assembly:          Machine code (hex):   What it does:
    // ADDI x1, x0, 0    32'h00000093          x1 = 0  (fib[n-2])
    // ADDI x2, x0, 1    32'h00100113          x2 = 1  (fib[n-1])
    // ADDI x3, x0, 10   32'h00A00193          x3 = 10 (loop counter)
    // ADD  x4, x1, x2   32'h002081B3          x4 = x1 + x2 (next fib)
    // ADD  x1, x0, x2   32'h00200033  (wrong) -- see note below
    // ADD  x2, x0, x4   32'h00400133          x2 = x4
    // ADDI x3, x3, -1   32'hFFF18193          x3 = x3 - 1
    // BEQ  x3, x0, end  32'h00018463          if x3==0, jump to end
    // (loop back -- we'll handle jumps after adding branch support)
    //
    // For now, preload with simple sequential instructions to test
    // that fetch works correctly. We'll update this in the testbench
    // once the full pipeline is running.

    initial begin
        // NOP = ADDI x0, x0, 0 -- does nothing, safe default
        // This fills the whole memory with NOPs first so uninitialized
        // slots don't cause undefined behavior
        for (int i = 0; i < 64; i++) begin
            mem[i] = 32'h00000013; // NOP
        end

        // Simple test program: load some values and add them
        // ADDI x1, x0, 5    -- x1 = 5
        mem[0] = 32'h00500093;
        // ADDI x2, x0, 3    -- x2 = 3
        mem[1] = 32'h00300113;
        // ADD  x3, x1, x2   -- x3 = x1 + x2 = 8
        mem[2] = 32'h002081B3;
        // ADDI x4, x3, 10   -- x4 = x3 + 10 = 18
        mem[3] = 32'h00A18213;
        // SUB  x5, x4, x1   -- x5 = x4 - x1 = 13
        mem[4] = 32'h401202B3;
        // Remaining slots are NOPs
    end

    // Combinational read -- PC is a byte address, divide by 4 for index
    // The [5:0] means we only use the lower 6 bits -> 64 possible addresses
    assign instr = mem[pc[7:2]];

endmodule
