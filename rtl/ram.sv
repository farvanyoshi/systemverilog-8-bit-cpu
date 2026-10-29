// Data memory, 256 x 8. Combinational read, write on the clock edge.
module ram
  import cpu_pkg::*;
(
  input  logic  clk,
  input  data_t addr,
  input  logic  we,
  input  data_t wdata,
  output data_t rdata
);

  data_t mem[2**XLEN];

  initial foreach (mem[i]) mem[i] = '0;

  always_ff @(posedge clk) begin
    if (we) mem[addr] <= wdata;
  end

  assign rdata = mem[addr];

endmodule
