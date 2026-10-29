// Data stack pointer. The stack is full-descending: PUSH writes to sp - 1
// and then moves sp there, and POP reads sp and then increments it.
module data_stack
  import cpu_pkg::*;
(
  input  logic  clk,
  input  logic  clear,
  input  logic  inc,
  input  logic  dec,

  output data_t sp,
  output data_t sp_dec   // sp - 1, the address PUSH writes to
);

  assign sp_dec = sp - 1'b1;

  always_ff @(posedge clk) begin
    if (clear)    sp <= '0;
    else if (dec) sp <= sp_dec;
    else if (inc) sp <= sp + 1'b1;
  end

endmodule
