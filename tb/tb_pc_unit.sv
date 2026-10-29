module tb_pc_unit;
  import cpu_pkg::*;

  logic    clk, clear, hold, redirect;
  pc_t     ir_pc, imm11, ret_addr, pc;
  pc_sel_e pc_sel;
  cond_e   cond;
  flags_t  flags;

  pc_unit dut (.*);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  int errors = 0;

  // Apply one execute-stage instruction and check the PC after the edge.
  task automatic step(pc_sel_e sel, cond_e c, pc_t imm, pc_t want, logic want_redirect);
    pc_sel = sel;
    cond   = c;
    imm11  = imm;
    #1;
    if (redirect !== want_redirect) begin
      $display("FAIL %s/%s: redirect=%b", sel.name(), c.name(), redirect);
      errors++;
    end
    @(posedge clk);
    #1;
    if (pc !== want) begin
      $display("FAIL %s/%s imm=%h ir_pc=%h: pc=%h want %h", sel.name(), c.name(), imm, ir_pc, pc, want);
      errors++;
    end
  endtask

  initial begin
    clear    = 1'b1;
    hold     = 1'b0;
    ir_pc    = '0;
    imm11    = '0;
    ret_addr = 11'h123;
    pc_sel   = PC_SEQ;
    cond     = COND_ALWAYS;
    flags    = '0;
    @(posedge clk);
    #1;
    clear = 1'b0;
    if (pc !== '0) begin $display("FAIL clear"); errors++; end

    step(PC_SEQ, COND_ALWAYS, 'h7FF, 11'd1, 1'b0);
    step(PC_SEQ, COND_ALWAYS, 'h000, 11'd2, 1'b0);

    hold = 1'b1;
    step(PC_SEQ, COND_ALWAYS, 'h000, 11'd2, 1'b0);
    hold = 1'b0;

    // Relative branches: offset from ir_pc, sign-extended.
    ir_pc = 11'd7;
    flags = '{v: 1'b0, n: 1'b0, z: 1'b1, c: 1'b0};
    step(PC_REL, COND_Z, 11'd4, 11'd11, 1'b1);
    ir_pc = 11'd11;
    step(PC_REL, COND_N, 11'd4, 11'd12, 1'b0);  // not taken: pc + 1
    flags = '{v: 1'b1, n: 1'b1, z: 1'b0, c: 1'b0};
    ir_pc = 11'd20;
    step(PC_REL, COND_N, -11'sd5, 11'd15, 1'b1);
    step(PC_REL, COND_V, -11'sd20, 11'd0, 1'b1);
    step(PC_REL, COND_Z, 11'd3, 11'd1, 1'b0);
    ir_pc = 11'd2;
    step(PC_REL, COND_ALWAYS, -11'sd3, 11'h7FF, 1'b1);  // wraps

    step(PC_ABS, COND_ALWAYS, 11'h456, 11'h456, 1'b1);
    step(PC_RET, COND_ALWAYS, 11'h000, 11'h123, 1'b1);

    if (errors != 0) $fatal(1, "tb_pc_unit: %0d errors", errors);
    $display("tb_pc_unit: PASS");
    $finish;
  end
endmodule
