// cpu_top.sv
// Top-level module for the 5-stage pipelined RISC-V CPU.
//
// This file contains NO new logic -- it's purely wiring. Every
// computation happens inside the submodules. This file just connects
// them together in the correct pipeline order.
//
// Reading strategy: follow the signal names through the file from top
// to bottom, and you'll trace the path an instruction takes:
//   PC → imem → IF/ID register → decoder+regfile → ID/EX register
//   → ALU → EX/MEM register → dmem → MEM/WB register → regfile write

`timescale 1ns/1ps

module cpu_top (
    input  logic clk,
    input  logic rst
    // No other top-level I/O needed for simulation -- we inspect
    // internal signals directly in the testbench.
);

// ============================================================
// SECTION 1: IF STAGE SIGNALS
// These are the wires between the PC, instruction memory, and
// the IF/ID pipeline register.
// ============================================================

    // PC outputs
    logic [31:0] pc_current;       // what PC holds right now (this cycle's fetch address)

    // Stall/branch wires -- driven by hazard unit (week 5) and branch
    // logic (week 6). For now, tie them to safe defaults so the pipeline
    // runs without hazard handling and we can verify basic correctness first.
    logic        stall;            // week 5: will come from hazard unit
    wire         branch_taken;     // week 6: will come from EX/MEM stage
    logic [31:0] branch_target;    // week 6: will come from EX stage added
    logic id_ex_flush;             // insert bubble into ID/EX from hazard unit
    // assign stall         = 1'b0;
    // assign branch_taken  = 1'b0;   // remove placeholders
    // assign branch_target = 32'b0;
    logic if_flush;
    logic haz_id_ex_flush;

    // Instruction memory output
    logic [31:0] if_instr;         // instruction fetched this cycle

    // IF/ID register outputs (what IF/ID holds -- inputs to ID stage)
    logic [31:0] id_instr;         // instruction now in ID stage
    logic [31:0] id_pc;            // PC of instruction now in ID stage

// ============================================================
// SECTION 2: ID STAGE SIGNALS
// Decoder outputs and register file outputs. These are all
// combinational -- they're computed the same cycle the instruction
// sits in the ID stage.
// ============================================================

    // Decoder outputs -- control signals for this instruction
    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [31:0] id_imm;
    logic [2:0]  id_alu_ctrl;
    logic        id_alu_src;
    logic        id_reg_write;
    logic        id_mem_read;
    logic        id_mem_write;
    logic        id_branch;
    logic        id_mem_to_reg;

    // Register file outputs -- values read this cycle
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;

    // Register file write inputs (driven from WB stage below -- declared
    // early here so they're in scope for the regfile instantiation)
    logic        wb_reg_write;
    logic [4:0]  wb_rd_addr;
    logic [31:0] wb_write_data;

    // ID/EX register outputs (what ID/EX holds -- inputs to EX stage)
    logic [31:0] ex_pc;
    logic [31:0] ex_rs1_data, ex_rs2_data;
    logic [31:0] ex_imm;
    logic [4:0]  ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
    logic [2:0]  ex_alu_ctrl;
    logic        ex_alu_src;
    logic        ex_reg_write;
    logic        ex_mem_read;
    logic        ex_mem_write;
    logic        ex_branch;
    logic        ex_mem_to_reg;

// ============================================================
// SECTION 3: EX STAGE SIGNALS
// ALU inputs, ALU outputs. The only combinational mux here
// is the ALU source mux (use rs2 or immediate as operand B).
// ============================================================

    logic [31:0] ex_alu_operand_b;  // either rs2 or immediate
    logic [31:0] ex_alu_result;
    logic        ex_zero;

    // EX/MEM register outputs (inputs to MEM stage)
    logic [31:0] mem_alu_result;
    logic [31:0] mem_rs2_data;
    logic [4:0]  mem_rd_addr;
    logic        mem_zero;
    logic        mem_reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_branch;
    logic        mem_mem_to_reg;  // carried through EX/MEM for WB use

// ============================================================
// SECTION 4: MEM STAGE SIGNALS
// Data memory output. We also need to carry mem_to_reg forward
// through EX/MEM, which our current ex_mem_reg doesn't support.
// We handle this with a simple register below.
// ============================================================

    logic [31:0] mem_read_data;    // value read from data memory (LW)

    // MEM/WB register outputs (inputs to WB stage)
    logic [31:0] wb_alu_result;
    logic [31:0] wb_mem_data;
    logic        wb_mem_to_reg;

// ============================================================
// SECTION 5: WB STAGE SIGNALS
// The writeback mux: choose between ALU result and memory data.
// ============================================================
    // wb_reg_write, wb_rd_addr, wb_write_data declared in Section 2
    // (they needed to be in scope for the regfile port connection)

// ============================================================
// MODULE INSTANTIATIONS
// Now wire everything up. Each module gets exactly the signals
// it needs, named exactly as its port list specifies.
// ============================================================

    // --- IF: Program Counter ---
    pc_reg pc_inst (
        .clk           (clk),
        .rst           (rst),
        .stall         (stall),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .pc            (pc_current)
    );

    // --- IF: Instruction Memory ---
    // PC feeds straight in, instruction comes straight out.
    imem imem_inst (
        .pc    (pc_current),
        .instr (if_instr)
    );

    // --- IF/ID Pipeline Register ---
    // Captures the fetched instruction and its PC at end of IF cycle.
    // flush=0 until we add branch handling in week 6.
    if_id_reg if_id_inst (
        .clk       (clk),
        .rst       (rst),
        .stall     (stall),
        .flush     (if_flush),         // flush signal
        .instr_in  (if_instr),
        .pc_in     (pc_current),
        .instr_out (id_instr),
        .pc_out    (id_pc)
    );

    // --- ID: Decoder ---
    // Looks at the instruction sitting in IF/ID and produces
    // all the control signals and field extractions.
    decoder dec_inst (
        .instr      (id_instr),
        .rs1_addr   (id_rs1_addr),
        .rs2_addr   (id_rs2_addr),
        .rd_addr    (id_rd_addr),
        .imm        (id_imm),
        .alu_ctrl   (id_alu_ctrl),
        .alu_src    (id_alu_src),
        .reg_write  (id_reg_write),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .branch     (id_branch),
        .mem_to_reg (id_mem_to_reg)
    );

    // --- ID: Register File ---
    // Two reads (rs1, rs2) happen in ID using the addresses from the decoder.
    // The write port is driven from WB stage signals (wb_*) -- this is the
    // "loop back" connection that makes register results visible to future instr.
    regfile regfile_inst (
        .clk      (clk),
        .we       (wb_reg_write),
        .rs1_addr (id_rs1_addr),
        .rs2_addr (id_rs2_addr),
        .rd_addr  (wb_rd_addr),
        .rd_data  (wb_write_data),
        .rs1_data (id_rs1_data),
        .rs2_data (id_rs2_data)
    );

    // --- ID/EX Pipeline Register ---
    // Carries everything the EX stage will need -- register values,
    // immediate, all control signals, plus register addresses for
    // the forwarding unit that arrives in week 5.
    id_ex_reg id_ex_inst (
        .clk          (clk),
        .rst          (rst),
        .flush        (id_ex_flush),          // week 6: wire to branch flush
        .pc_in        (id_pc),
        .rs1_data_in  (id_rs1_data),
        .rs2_data_in  (id_rs2_data),
        .imm_in       (id_imm),
        .rs1_addr_in  (id_rs1_addr),
        .rs2_addr_in  (id_rs2_addr),
        .rd_addr_in   (id_rd_addr),
        .alu_ctrl_in  (id_alu_ctrl),
        .alu_src_in   (id_alu_src),
        .reg_write_in (id_reg_write),
        .mem_read_in  (id_mem_read),
        .mem_write_in (id_mem_write),
        .branch_in    (id_branch),
        .pc_out       (ex_pc),
        .rs1_data_out (ex_rs1_data),
        .rs2_data_out (ex_rs2_data),
        .imm_out      (ex_imm),
        .rs1_addr_out (ex_rs1_addr),
        .rs2_addr_out (ex_rs2_addr),
        .rd_addr_out  (ex_rd_addr),
        .alu_ctrl_out (ex_alu_ctrl),
        .alu_src_out  (ex_alu_src),
        .reg_write_out(ex_reg_write),
        .mem_read_out (ex_mem_read),
        .mem_write_out(ex_mem_write),
        .branch_out   (ex_branch)
    );

    // NOTE: id_ex_reg doesn't have a mem_to_reg port yet -- it was built
    // before we added that signal to the decoder. We carry it through a
    // simple register below alongside the EX/MEM and MEM/WB registers.
    // This is cleaner than re-opening id_ex_reg right now.
    logic ex_mem_to_reg_r, mem_mem_to_reg_r;
    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_to_reg_r  <= 1'b0;
            mem_mem_to_reg_r <= 1'b0;
        end else begin
            ex_mem_to_reg_r  <= id_mem_to_reg;
            mem_mem_to_reg_r <= ex_mem_to_reg_r;
        end
    end
/* REPLACE ENTIRE UNIT W FORWARDING UNIT
    // --- EX: ALU Source Mux ---
    // Decoder says alu_src=1: use the sign-extended immediate as operand B.
    // alu_src=0: use rs2 value (register-to-register operation).
    assign ex_alu_operand_b = ex_alu_src ? ex_imm : ex_rs2_data;

    // --- EX: ALU ---
    alu alu_inst (
        .a        (ex_rs1_data),
        .b        (ex_alu_operand_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .zero     (ex_zero)
    );
*/
    // FORWARDING UNIT : compares register addresses across pipeline stages and generates MUX signals to tell the EX
    // where to get its operands.
    logic [1:0] forward_a, forward_b;
    forwarding_unit fwd_inst (
        .ex_rs1_addr  (ex_rs1_addr),
        .ex_rs2_addr  (ex_rs2_addr),
        .mem_rd_addr  (mem_rd_addr),
        .mem_reg_write(mem_reg_write),
        .wb_rd_addr   (wb_rd_addr),
        .wb_reg_write (wb_reg_write),
        .forward_a    (forward_a),
        .forward_b    (forward_b)
        );
    // --- Hazard Unit ---
    // Detects load-use hazards and generates stall + bubble signals.
    hazard_unit haz_inst (
        .ex_rd_addr   (ex_rd_addr),
        .ex_mem_read  (ex_mem_read),
        .id_rs1_addr  (id_rs1_addr),
        .id_rs2_addr  (id_rs2_addr),
        .stall        (stall),
        .id_ex_flush  (haz_id_ex_flush)
    );
        // --- EX: Forwarding Muxes + ALU Source Mux ---
        // forward_a/forward_b select the actual value that feeds the ALU:
        //   00 = from register file (no hazard)
        //   10 = forwarded from EX/MEM stage (1 cycle ahead)
        //   01 = forwarded from MEM/WB stage (2 cycles ahead)
        logic [31:0] ex_forward_a_out;
        logic [31:0] ex_forward_b_out;

        always_comb begin
            case (forward_a)
                2'b10:   ex_forward_a_out = mem_alu_result;
                2'b01:   ex_forward_a_out = wb_write_data;
                default: ex_forward_a_out = ex_rs1_data;
            endcase

            case (forward_b)
                2'b10:   ex_forward_b_out = mem_alu_result;
                2'b01:   ex_forward_b_out = wb_write_data;
                default: ex_forward_b_out = ex_rs2_data;
            endcase
        end

        // ALU source mux: immediate overrides forwarded rs2 for I-type instructions
        assign ex_alu_operand_b = ex_alu_src ? ex_imm : ex_forward_b_out;

        // --- EX: ALU ---
        alu alu_inst (
            .a        (ex_forward_a_out),
            .b        (ex_alu_operand_b),
            .alu_ctrl (ex_alu_ctrl),
            .result   (ex_alu_result),
            .zero     (ex_zero)
        );
    // Branch Target Adder: computes PC + imm while the ALU is computing rs1-rs2 for the branch condition check.
    logic [31:0] ex_branch_target;
    branch_adder branch_adder_inst (
        .pc            (ex_pc),
        .imm           (ex_imm),
        .target        (ex_branch_target)
    );

    // --- EX/MEM Pipeline Register ---
    ex_mem_reg ex_mem_inst (
        .clk           (clk),
        .rst           (rst),
        .alu_result_in (ex_alu_result),
        .rs2_data_in   (ex_forward_b_out),     // forward the stored data for SW
        .rd_addr_in    (ex_rd_addr),
        .zero_flag_in  (ex_zero),
        .reg_write_in  (ex_reg_write),
        .mem_read_in   (ex_mem_read),
        .mem_write_in  (ex_mem_write),
        .branch_in     (ex_branch),
        .alu_result_out(mem_alu_result),
        .rs2_data_out  (mem_rs2_data),
        .rd_addr_out   (mem_rd_addr),
        .zero_flag_out (mem_zero),
        .reg_write_out (mem_reg_write),
        .mem_read_out  (mem_read),
        .mem_write_out (mem_write),
        .branch_out    (mem_branch)
    );

    // --- MEM: Data Memory ---
    // ALU result is the byte address (for both LW and SW).
    // For SW: rs2_data carried through EX/MEM is what gets stored.
    // For LW: read_data is what gets written back to the register file.
    dmem dmem_inst (
        .clk        (clk),
        .we         (mem_write),
        .addr       (mem_alu_result),
        .write_data (mem_rs2_data),
        .read_data  (mem_read_data)
    );

    // --- MEM/WB Pipeline Register ---
    mem_wb_reg mem_wb_inst (
        .clk           (clk),
        .rst           (rst),
        .alu_result_in (mem_alu_result),
        .mem_data_in   (mem_read_data),
        .rd_addr_in    (mem_rd_addr),
        .reg_write_in  (mem_reg_write),
        .mem_to_reg_in (mem_mem_to_reg_r),  // from our carry-through register
        .alu_result_out(wb_alu_result),
        .mem_data_out  (wb_mem_data),
        .rd_addr_out   (wb_rd_addr),
        .reg_write_out (wb_reg_write),
        .mem_to_reg_out(wb_mem_to_reg)
    );

    // --- WB: Writeback Mux ---
    // mem_to_reg=1 means this was a LW -- write the loaded value.
    // mem_to_reg=0 means use the ALU result (ADD, SUB, ADDI etc.)
    assign wb_write_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

    // wb_write_data and wb_reg_write and wb_rd_addr feed back into
    // the regfile instantiation above -- completing the pipeline loop.
    // Brach control: flush if IF/ID (wrong fetch) and ID/EX (wrong decode)
    // Branch resolved in EX stage -- use ex_branch and ex_zero directly.
        // This avoids a clock-edge race where mem_branch/mem_zero update at
        // the same posedge that pc_reg reads branch_taken.
        // Flushing: when branch taken, flush IF/ID (1 wrong fetch) only --
        // the instruction in ID/EX is the one right after the branch which
        // was fetched before we knew the branch was taken.
        assign branch_taken  = ex_branch && ex_zero;
        assign branch_target = ex_branch_target;
        assign if_flush      = branch_taken;
        assign id_ex_flush   = haz_id_ex_flush || branch_taken;

endmodule
