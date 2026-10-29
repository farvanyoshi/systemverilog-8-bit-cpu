// Instruction ROM, 2048 x 16, combinational read. Locations not loaded from
// INIT_FILE hold HALT, so running off the end of a program stops the CPU.
module rom
  import cpu_pkg::*;
#(
  parameter string INIT_FILE = ""
) (
  input  pc_t    addr,
  output instr_t data
);

  instr_t mem[2**PCW];

  initial begin
    foreach (mem[i]) mem[i] = {OP_HALT, 11'b0};
    if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
  end

  assign data = mem[addr];

endmodule
