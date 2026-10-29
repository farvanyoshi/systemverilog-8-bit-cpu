// Hardware return-address stack used by ACALL, RCALL and RET. It is separate
// from data memory and wraps silently when it overflows or underflows.
module ret_stack
  import cpu_pkg::*;
#(
  parameter int DEPTH_LOG2 = 8
) (
  input  logic clk,
  input  logic clear,
  input  logic push,
  input  logic pop,
  input  pc_t  push_addr,
  output pc_t  top
);

  pc_t                   mem[2**DEPTH_LOG2];
  logic [DEPTH_LOG2-1:0] ptr;  // next free slot

  assign top = mem[ptr - 1'b1];

  always_ff @(posedge clk) begin
    if (clear) begin
      ptr <= '0;
    end else if (push) begin
      mem[ptr] <= push_addr;
      ptr      <= ptr + 1'b1;
    end else if (pop) begin
      ptr <= ptr - 1'b1;
    end
  end

endmodule
