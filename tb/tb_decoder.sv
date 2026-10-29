// Checks the decoder against the per-opcode properties in docs/ISA.md.
module tb_decoder;
  import cpu_pkg::*;

  opcode_e opcode;
  ctrl_t   ctrl;

  decoder dut (.*);

  int errors = 0;

  task automatic expect_eq(opcode_e op, string what, int got, int want);
    if (got != want) begin
      $display("FAIL %s: %s = %0d, want %0d", op.name(), what, got, want);
      errors++;
    end
  endtask

  initial begin
    for (int i = 0; i < 32; i++) begin
      opcode_e op;
      logic    alu_rr, imm_arith, load, store, branch, call;

      op     = opcode_e'(i);
      opcode = op;
      #1;

      alu_rr    = i <= int'(OP_ROR);
      imm_arith = op inside {OP_ADDI, OP_SUBI};
      load      = op inside {OP_LDA, OP_LIA, OP_POP};
      store     = op inside {OP_SDA, OP_SIA, OP_PUSH};
      branch    = op inside {OP_BRZ, OP_BRN, OP_BRV};
      call      = op inside {OP_ACALL, OP_RCALL};

      expect_eq(op, "reg_we",   ctrl.reg_we,   int'(alu_rr || imm_arith || load || op == OP_LDI));
      expect_eq(op, "flags_we", ctrl.flags_we, int'(alu_rr || imm_arith));
      expect_eq(op, "mem_we",   ctrl.mem_we,   int'(store));
      expect_eq(op, "rb_is_rd", ctrl.rb_is_rd, int'(store));
      expect_eq(op, "ra_is_rd", ctrl.ra_is_rd, int'(imm_arith));
      expect_eq(op, "alu_b_imm", ctrl.alu_b_imm, int'(imm_arith));
      expect_eq(op, "sp_dec",   ctrl.sp_dec,   int'(op == OP_PUSH));
      expect_eq(op, "sp_inc",   ctrl.sp_inc,   int'(op == OP_POP));
      expect_eq(op, "ras_push", ctrl.ras_push, int'(call));
      expect_eq(op, "ras_pop",  ctrl.ras_pop,  int'(op == OP_RET));
      expect_eq(op, "soft_reset", ctrl.soft_reset, int'(op == OP_RESET));
      expect_eq(op, "halt",     ctrl.halt,     int'(op == OP_HALT));

      if (alu_rr) expect_eq(op, "alu_op", ctrl.alu_op, i);
      if (op == OP_ADDI) expect_eq(op, "alu_op", ctrl.alu_op, int'(ALU_ADD));
      if (op == OP_SUBI) expect_eq(op, "alu_op", ctrl.alu_op, int'(ALU_SUB));

      if (ctrl.reg_we)
        expect_eq(op, "wb_sel", ctrl.wb_sel,
                  int'(load ? WB_MEM : op == OP_LDI ? WB_IMM : WB_ALU));

      if (load || store)
        expect_eq(op, "addr_sel", ctrl.addr_sel,
                  int'(op inside {OP_LDA, OP_SDA} ? ADDR_DIRECT :
                       op inside {OP_LIA, OP_SIA} ? ADDR_INDEXED :
                       op == OP_PUSH ? ADDR_SP_DEC : ADDR_SP));

      expect_eq(op, "pc_sel", ctrl.pc_sel,
                int'(branch || op == OP_RCALL ? PC_REL :
                     op inside {OP_JMP, OP_ACALL} ? PC_ABS :
                     op == OP_RET ? PC_RET : PC_SEQ));

      if (ctrl.pc_sel == PC_REL)
        expect_eq(op, "cond", ctrl.cond,
                  int'(op == OP_BRZ ? COND_Z : op == OP_BRN ? COND_N :
                       op == OP_BRV ? COND_V : COND_ALWAYS));
    end

    if (errors != 0) $fatal(1, "tb_decoder: %0d errors", errors);
    $display("tb_decoder: PASS");
    $finish;
  end
endmodule
