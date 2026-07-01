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
);

// ============================================================
// ALL SIGNAL DECLARATIONS (must come before any always/instantiation)
// ============================================================

    // IF stage
    logic [31:0] pc_current;
    logic        stall;
    wire         branch_taken;
    wire  [31:0] branch_target;
    logic        id_ex_flush;
    logic        if_flush;
    logic        haz_id_ex_flush;
    logic        branch_taken_comb;
    logic [31:0] if_instr;
    logic [31:0] id_instr;
    logic [31:0] id_pc;

    // ID stage
    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [31:0] id_imm;
    logic [2:0]  id_alu_ctrl;
    logic        id_alu_src;
    logic        id_reg_write;
    logic        id_mem_read;
    logic        id_mem_write;
    logic        id_branch;
    logic        id_mem_to_reg;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;

    // WB stage write inputs (declared early for regfile port connection)
    logic        wb_reg_write;
    logic [4:0]  wb_rd_addr;
    logic [31:0] wb_write_data;

    // ID/EX outputs
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

    // EX stage
    logic [1:0]  forward_a, forward_b;
    logic [31:0] ex_forward_a_out;
    logic [31:0] ex_forward_b_out;
    logic [31:0] ex_alu_operand_b;
    logic [31:0] ex_alu_result;
    logic        ex_zero;
    logic [31:0] ex_branch_target;

    // EX/MEM outputs
    logic [31:0] mem_alu_result;
    logic [31:0] mem_rs2_data;
    logic [4:0]  mem_rd_addr;
    logic        mem_zero;
    logic        mem_reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_branch;

    // mem_to_reg carry-through registers
    logic        ex_mem_to_reg_r, mem_mem_to_reg_r;

    // MEM stage
    logic [31:0] mem_read_data;

    // MEM/WB outputs
    logic [31:0] wb_alu_result;
    logic [31:0] wb_mem_data;
    logic        wb_mem_to_reg;

// ============================================================
// COMBINATIONAL LOGIC (always_comb blocks)
// ============================================================

    // Forwarding muxes
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

    // ALU source mux
    assign ex_alu_operand_b = ex_alu_src ? ex_imm : ex_forward_b_out;

    // Branch logic
    always_comb branch_taken_comb = ex_branch & ex_zero;
    assign branch_taken  = branch_taken_comb;
    assign branch_target = ex_branch_target;
    assign if_flush      = branch_taken_comb;
    assign id_ex_flush   = haz_id_ex_flush | branch_taken_comb;

    // WB mux -- use explicit check to avoid x propagation from uninitialized mem_to_reg
    assign wb_write_data = (wb_mem_to_reg === 1'b1) ? wb_mem_data : wb_alu_result;

    // mem_to_reg carry-through
    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_to_reg_r  <= 1'b0;
            mem_mem_to_reg_r <= 1'b0;
        end else begin
            ex_mem_to_reg_r  <= id_mem_to_reg;
            mem_mem_to_reg_r <= ex_mem_to_reg_r;
        end
    end

// ============================================================
// MODULE INSTANTIATIONS
// ============================================================

    // IF: Program Counter
    pc_reg pc_inst (
        .clk           (clk),
        .rst           (rst),
        .stall         (stall),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .pc            (pc_current)
    );

    // IF: Instruction Memory
    imem imem_inst (
        .pc    (pc_current),
        .instr (if_instr)
    );

    // IF/ID Pipeline Register
    if_id_reg if_id_inst (
        .clk       (clk),
        .rst       (rst),
        .stall     (stall),
        .flush     (if_flush),
        .instr_in  (if_instr),
        .pc_in     (pc_current),
        .instr_out (id_instr),
        .pc_out    (id_pc)
    );

    // ID: Decoder
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

    // ID: Register File
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

    // ID/EX Pipeline Register
    id_ex_reg id_ex_inst (
        .clk          (clk),
        .rst          (rst),
        .flush        (id_ex_flush),
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

    // EX: Forwarding Unit
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

    // Hazard Unit
    hazard_unit haz_inst (
        .ex_rd_addr   (ex_rd_addr),
        .ex_mem_read  (ex_mem_read),
        .id_rs1_addr  (id_rs1_addr),
        .id_rs2_addr  (id_rs2_addr),
        .stall        (stall),
        .id_ex_flush  (haz_id_ex_flush)
    );

    // EX: ALU
    alu alu_inst (
        .a        (ex_forward_a_out),
        .b        (ex_alu_operand_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .zero     (ex_zero)
    );

    // EX: Branch Target Adder
    branch_adder branch_adder_inst (
        .pc     (ex_pc),
        .imm    (ex_imm),
        .target (ex_branch_target)
    );

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem_inst (
        .clk           (clk),
        .rst           (rst),
        .flush         (branch_taken_comb),
        .alu_result_in (ex_alu_result),
        .rs2_data_in   (ex_forward_b_out),
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

    // MEM: Data Memory
    dmem dmem_inst (
        .clk        (clk),
        .we         (mem_write),
        .addr       (mem_alu_result),
        .write_data (mem_rs2_data),
        .read_data  (mem_read_data)
    );

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb_inst (
        .clk           (clk),
        .rst           (rst),
        .flush         (branch_taken_comb),
        .alu_result_in (mem_alu_result),
        .mem_data_in   (mem_read_data),
        .rd_addr_in    (mem_rd_addr),
        .reg_write_in  (mem_reg_write),
        .mem_to_reg_in (mem_mem_to_reg_r),
        .alu_result_out(wb_alu_result),
        .mem_data_out  (wb_mem_data),
        .rd_addr_out   (wb_rd_addr),
        .reg_write_out (wb_reg_write),
        .mem_to_reg_out(wb_mem_to_reg)
    );

endmodule
