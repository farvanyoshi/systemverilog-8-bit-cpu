// Program counter and next-PC selection. pc is the fetch address. The
// instruction in execute was fetched from ir_pc, and branch targets are
// relative to it.
module pc_unit
  import cpu_pkg::*;
(
  input  logic    clk,
  input  logic    clear,
  input  logic    hold,

  input  pc_t     ir_pc,
  input  pc_sel_e pc_sel,
  input  cond_e   cond,
  /* verilator lint_off UNUSEDSIGNAL */  // no branch tests C
  input  flags_t  flags,
  /* verilator lint_on UNUSEDSIGNAL */
  input  pc_t     imm11,     // absolute target, or signed offset for PC_REL
  input  pc_t     ret_addr,  // top of the return stack

  output pc_t     pc,
  output logic    redirect   // execute is changing the flow; squash the fetch
);

  logic taken;
  pc_t  target;

  always_comb begin
    unique case (cond)
      COND_ALWAYS: taken = 1'b1;
      COND_Z:      taken = flags.z;
      COND_N:      taken = flags.n;
      COND_V:      taken = flags.v;
      default:     taken = 1'b0;
    endcase
  end

  always_comb begin
    unique case (pc_sel)
      PC_REL:  target = ir_pc + imm11;  // 11-bit wraparound sign-extends
      PC_ABS:  target = imm11;
      PC_RET:  target = ret_addr;
      default: target = pc + 1'b1;
    endcase
  end

  assign redirect = (pc_sel == PC_REL) ? taken : (pc_sel != PC_SEQ);

  always_ff @(posedge clk) begin
    if (clear)      pc <= '0;
    else if (!hold) pc <= redirect ? target : pc + 1'b1;
  end

endmodule
