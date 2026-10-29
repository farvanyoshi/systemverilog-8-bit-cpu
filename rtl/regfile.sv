// Eight 8-bit registers, two combinational read ports and one write port.
// r0 always reads as zero. clear zeroes r1-r7 on the next clock edge.
module regfile
  import cpu_pkg::*;
(
  input  logic     clk,
  input  logic     clear,

  input  reg_idx_t ra_addr,
  output data_t    ra_data,
  input  reg_idx_t rb_addr,
  output data_t    rb_data,

  input  logic     we,
  input  reg_idx_t wr_addr,
  input  data_t    wr_data
);

  data_t regs[1:7];

  always_ff @(posedge clk) begin
    if (clear) begin
      for (int i = 1; i <= 7; i++) regs[i] <= '0;
    end else if (we && wr_addr != '0) begin
      regs[wr_addr] <= wr_data;
    end
  end

  assign ra_data = (ra_addr == '0) ? '0 : regs[ra_addr];
  assign rb_data = (rb_addr == '0) ? '0 : regs[rb_addr];

endmodule
