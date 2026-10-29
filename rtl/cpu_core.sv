// Two-stage CPU core. Each clock edge fetches imem[pc] into the instruction
// register while the previous instruction executes. A taken redirect squashes
// the fetched instruction to a NOP.
module cpu_core
  import cpu_pkg::*;
(
  input  logic   clk,
  input  logic   rst,      // synchronous, active high

  output pc_t    imem_addr,
  input  instr_t imem_data,

  output data_t  dmem_addr,
  output logic   dmem_we,
  output data_t  dmem_wdata,
  input  data_t  dmem_rdata,

  output logic   halted
);

  // ---------------------------------------------------------------- fetch
  instr_t ir;
  pc_t    ir_pc;  // address ir was fetched from
  pc_t    pc;
  logic   redirect;

  // ---------------------------------------------------------------- decode
  opcode_e  opcode;
  reg_idx_t rd, rs1, rs2;
  data_t    imm8;
  logic [4:0] imm5;
  pc_t      imm11;
  ctrl_t    ctrl;

  assign opcode = opcode_e'(ir[15:11]);
  assign rd     = ir[10:8];
  assign rs1    = ir[7:5];
  assign rs2    = ir[4:2];
  assign imm8   = ir[7:0];
  assign imm5   = ir[4:0];
  assign imm11  = ir[10:0];

  decoder u_decoder (.opcode, .ctrl);

  // A RESET instruction clears architectural state like the reset pin. HALT
  // freezes the pipeline, and since the IR keeps holding HALT it stays frozen.
  logic clear, hold;
  assign clear  = rst || ctrl.soft_reset;
  assign hold   = ctrl.halt;
  assign halted = ctrl.halt;

  // ---------------------------------------------------------------- execute
  reg_idx_t ra_addr, rb_addr;
  data_t    ra_data, rb_data, wb_data;
  data_t    alu_b, alu_result;
  flags_t   flags, alu_flags;
  data_t    sp, sp_dec;
  pc_t      ret_addr;

  assign ra_addr = ctrl.ra_is_rd ? rd : rs1;
  assign rb_addr = ctrl.rb_is_rd ? rd : rs2;

  regfile u_regfile (
    .clk,
    .clear,
    .ra_addr,
    .ra_data,
    .rb_addr,
    .rb_data,
    .we      (ctrl.reg_we),
    .wr_addr (rd),
    .wr_data (wb_data)
  );

  assign alu_b = ctrl.alu_b_imm ? imm8 : rb_data;

  alu u_alu (
    .op       (ctrl.alu_op),
    .a        (ra_data),
    .b        (alu_b),
    .carry_in (flags.c),
    .result   (alu_result),
    .flags    (alu_flags)
  );

  always_ff @(posedge clk) begin
    if (clear)              flags <= '0;
    else if (ctrl.flags_we) flags <= alu_flags;
  end

  always_comb begin
    unique case (ctrl.wb_sel)
      WB_IMM:  wb_data = imm8;
      WB_MEM:  wb_data = dmem_rdata;
      default: wb_data = alu_result;
    endcase
  end

  // ---------------------------------------------------------------- memory
  data_stack u_data_stack (
    .clk,
    .clear,
    .inc    (ctrl.sp_inc),
    .dec    (ctrl.sp_dec),
    .sp,
    .sp_dec
  );

  always_comb begin
    unique case (ctrl.addr_sel)
      ADDR_INDEXED: dmem_addr = ra_data + data_t'(imm5);
      ADDR_SP:      dmem_addr = sp;
      ADDR_SP_DEC:  dmem_addr = sp_dec;
      default:      dmem_addr = imm8;
    endcase
  end

  assign dmem_we    = ctrl.mem_we && !rst;
  assign dmem_wdata = rb_data;

  // ---------------------------------------------------------------- control flow
  ret_stack u_ret_stack (
    .clk,
    .clear,
    .push      (ctrl.ras_push),
    .pop       (ctrl.ras_pop),
    .push_addr (ir_pc + 1'b1),
    .top       (ret_addr)
  );

  pc_unit u_pc_unit (
    .clk,
    .clear,
    .hold,
    .ir_pc,
    .pc_sel   (ctrl.pc_sel),
    .cond     (ctrl.cond),
    .flags,
    .imm11,
    .ret_addr,
    .pc,
    .redirect
  );

  assign imem_addr = pc;

  always_ff @(posedge clk) begin
    if (clear) begin
      ir    <= NOP_INSTR;
      ir_pc <= '0;
    end else if (!hold) begin
      ir    <= redirect ? NOP_INSTR : imem_data;
      ir_pc <= pc;
    end
  end

endmodule
