// Checks that the toolchain builds and runs a testbench against the package.
module tb_smoke;
  import cpu_pkg::*;

  initial begin
    if (NOP_INSTR !== 16'hE800) $fatal(1, "NOP_INSTR = %h", NOP_INSTR);
    if ($bits(flags_t) != 4) $fatal(1, "flags_t is %0d bits", $bits(flags_t));
    $display("tb_smoke: PASS");
    $finish;
  end
endmodule
