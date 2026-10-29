// Control unit: maps an instruction's opcode to datapath control signals.
module decoder
  import cpu_pkg::*;
(
  input  opcode_e opcode,
  output ctrl_t   ctrl
);

  always_comb begin
    ctrl = '{
      reg_we:     1'b0,
      wb_sel:     WB_ALU,
      ra_is_rd:   1'b0,
      rb_is_rd:   1'b0,
      alu_op:     ALU_ADD,
      alu_b_imm:  1'b0,
      flags_we:   1'b0,
      mem_re:     1'b0,
      mem_we:     1'b0,
      addr_sel:   ADDR_DIRECT,
      sp_inc:     1'b0,
      sp_dec:     1'b0,
      pc_sel:     PC_SEQ,
      cond:       COND_ALWAYS,
      ras_push:   1'b0,
      ras_pop:    1'b0,
      soft_reset: 1'b0,
      halt:       1'b0
    };

    unique case (opcode)
      // Register-register ALU ops share their encoding order with alu_op_e.
      OP_ADD, OP_ADC, OP_SUB, OP_SBC, OP_AND, OP_OR, OP_XOR,
      OP_NOT, OP_SHL, OP_SHR, OP_ASR, OP_ROL, OP_ROR: begin
        ctrl.reg_we   = 1'b1;
        ctrl.flags_we = 1'b1;
        ctrl.alu_op   = alu_op_e'(opcode[3:0]);
      end

      OP_ADDI, OP_SUBI: begin
        ctrl.reg_we    = 1'b1;
        ctrl.flags_we  = 1'b1;
        ctrl.ra_is_rd  = 1'b1;
        ctrl.alu_b_imm = 1'b1;
        ctrl.alu_op    = (opcode == OP_ADDI) ? ALU_ADD : ALU_SUB;
      end

      OP_LDI: begin
        ctrl.reg_we = 1'b1;
        ctrl.wb_sel = WB_IMM;
      end

      OP_LDA, OP_LIA: begin
        ctrl.reg_we   = 1'b1;
        ctrl.wb_sel   = WB_MEM;
        ctrl.mem_re   = 1'b1;
        ctrl.addr_sel = (opcode == OP_LDA) ? ADDR_DIRECT : ADDR_INDEXED;
      end

      OP_SDA, OP_SIA: begin
        ctrl.mem_we   = 1'b1;
        ctrl.rb_is_rd = 1'b1;
        ctrl.addr_sel = (opcode == OP_SDA) ? ADDR_DIRECT : ADDR_INDEXED;
      end

      OP_BRZ: begin ctrl.pc_sel = PC_REL; ctrl.cond = COND_Z; end
      OP_BRN: begin ctrl.pc_sel = PC_REL; ctrl.cond = COND_N; end
      OP_BRV: begin ctrl.pc_sel = PC_REL; ctrl.cond = COND_V; end

      OP_ACALL: begin ctrl.pc_sel = PC_ABS; ctrl.ras_push = 1'b1; end
      OP_JMP:   ctrl.pc_sel = PC_ABS;
      OP_RCALL: begin ctrl.pc_sel = PC_REL; ctrl.ras_push = 1'b1; end
      OP_RET:   begin ctrl.pc_sel = PC_RET; ctrl.ras_pop  = 1'b1; end

      OP_PUSH: begin
        ctrl.mem_we   = 1'b1;
        ctrl.rb_is_rd = 1'b1;
        ctrl.addr_sel = ADDR_SP_DEC;
        ctrl.sp_dec   = 1'b1;
      end

      OP_POP: begin
        ctrl.reg_we   = 1'b1;
        ctrl.wb_sel   = WB_MEM;
        ctrl.mem_re   = 1'b1;
        ctrl.addr_sel = ADDR_SP;
        ctrl.sp_inc   = 1'b1;
      end

      OP_NOP:   ;
      OP_RESET: ctrl.soft_reset = 1'b1;
      OP_HALT:  ctrl.halt       = 1'b1;

      default: ;
    endcase
  end

endmodule
